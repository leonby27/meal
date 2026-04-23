import asyncio
import base64
import io
import json
import logging
import re

import httpx
from PIL import Image

from app.config import settings

logger = logging.getLogger(__name__)

_JSON_SCHEMA = """{
  "name": "Название блюда",
  "total_grams": 350,
  "ingredients": [
    {"name": "Куриное яйцо (2 шт.)", "grams": 110, "protein": 14.0, "fat": 11.0, "carbs": 0.8, "calories": 155},
    {"name": "Помидоры", "grams": 80, "protein": 0.9, "fat": 0.2, "carbs": 3.2, "calories": 18},
    {"name": "Сыр твёрдый", "grams": 30, "protein": 7.5, "fat": 8.4, "carbs": 0.0, "calories": 105}
  ],
  "per_100g": {"protein": 10.5, "fat": 8.5, "carbs": 2.2, "calories": 127},
  "total": {"protein": 22.4, "fat": 19.6, "carbs": 4.0, "calories": 278}
}"""

# Shared instructions used by both the image and text prompts.
#
# IMPORTANT — piece-count format:
# For countable ingredients (eggs, sausages, cutlets, meatballs, shrimp,
# dumplings, cookies, slices of bread/pizza, etc.) the client parses
# "(N шт.)" out of the `name` field via regex r'\((\d+)\s*шт\.?\)' and shows
# a +/- stepper so the user can tweak the count. When the stepper is used,
# the client assumes `grams` = total weight for ALL pieces, and computes
# per-unit grams as grams / N.
#
# Do NOT add "(N шт.)" to bulk / non-countable ingredients (sauce, oil,
# grated cheese, salad leaves, rice, pasta, mince, etc.) — those should
# stay as free-form grams only.
_COMMON_RULES = """Правила формата ингредиентов:
- Для штучных ингредиентов (яйца, сосиски, котлеты, фрикадельки,
  креветки, пельмени, печенье, куски пиццы/хлеба и т.п.) добавь в конец
  name «(N шт.)», где N — целое количество штук.
  А в поле grams укажи СУММАРНЫЙ вес всех штук.
  Пример: "name": "Куриное яйцо (2 шт.)", "grams": 110.
- Для НЕштучных / массовых ингредиентов (соус, масло, тёртый сыр,
  листья салата, рис, макароны, фарш, порезанные овощи) «(N шт.)» НЕ
  добавляй — оставь просто название и вес в граммах.
- Считай БЖУ/калории для КАЖДОГО ингредиента отдельно — это нужно,
  чтобы при изменении количества штук клиент пересчитал итог.
- total должен быть равен сумме по ингредиентам (с точностью до 1–2%).

Ответь СТРОГО в формате JSON (без markdown, без текста до/после):
""" + _JSON_SCHEMA

SYSTEM_PROMPT = f"""Ты профессиональный диетолог-нутрициолог. Проанализируй фотографию еды и определи:
1. Название блюда
2. Список ингредиентов с примерными граммовками
3. БЖУ и калории на всю порцию и на 100 г

{_COMMON_RULES}"""

TEXT_SYSTEM_PROMPT = f"""Ты профессиональный диетолог-нутрициолог. По текстовому описанию еды определи:
1. Название блюда
2. Список ингредиентов с примерными граммовками
3. БЖУ и калории на всю порцию и на 100 г

Если пользователь указал граммовку — используй её. Если нет — оцени стандартную порцию.

{_COMMON_RULES}"""

MAX_DIMENSION = 768
JPEG_QUALITY = 75
MAX_TOKENS = 1800

HTTP_TIMEOUT = 60.0
MAX_ATTEMPTS = 3
RETRY_BASE_DELAY = 1.0


class AIRecognitionError(Exception):
    """Raised when AI recognition fails after retries or returns unparseable output."""

    def __init__(self, message: str, *, kind: str = "unknown", raw: str | None = None):
        super().__init__(message)
        self.kind = kind
        self.raw = raw


def normalize_image(image_bytes: bytes) -> str:
    """Convert any image to JPEG, resize if needed, return base64."""
    img = Image.open(io.BytesIO(image_bytes))

    if img.mode in ('RGBA', 'P', 'LA'):
        background = Image.new('RGB', img.size, (255, 255, 255))
        if img.mode == 'P':
            img = img.convert('RGBA')
        background.paste(img, mask=img.split()[-1] if 'A' in img.mode else None)
        img = background
    elif img.mode != 'RGB':
        img = img.convert('RGB')

    w, h = img.size
    if max(w, h) > MAX_DIMENSION:
        ratio = MAX_DIMENSION / max(w, h)
        img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
    jpeg_bytes = buf.getvalue()

    logger.info(
        "normalize_image: original=%d bytes, jpeg=%d bytes, size=%dx%d",
        len(image_bytes), len(jpeg_bytes), img.size[0], img.size[1],
    )
    return base64.b64encode(jpeg_bytes).decode('utf-8')


def _ai_url() -> str:
    return f"{settings.timeweb_ai_base_url}/{settings.timeweb_ai_agent_id}/v1/chat/completions"


def _ai_headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.timeweb_ai_token}",
        "Content-Type": "application/json",
    }


_CODE_FENCE_RE = re.compile(r"```(?:json)?\s*(\{.*?\})\s*```", re.DOTALL | re.IGNORECASE)
_TRAILING_COMMA_RE = re.compile(r",(\s*[}\]])")
_LINE_COMMENT_RE = re.compile(r"//[^\n]*")
_BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)


def _extract_json_candidate(content: str) -> str | None:
    """Try to pull a JSON object out of a noisy LLM response."""
    if not content:
        return None

    fence = _CODE_FENCE_RE.search(content)
    if fence:
        return fence.group(1)

    start = content.find('{')
    if start == -1:
        return None

    depth = 0
    in_string = False
    escape = False
    for i in range(start, len(content)):
        ch = content[i]
        if in_string:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return content[start:i + 1]

    return content[start:]


def _clean_json_text(text: str) -> str:
    text = _BLOCK_COMMENT_RE.sub('', text)
    text = _LINE_COMMENT_RE.sub('', text)
    text = _TRAILING_COMMA_RE.sub(r'\1', text)
    return text.strip()


def _parse_ai_response(data: dict) -> dict:
    try:
        content = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as e:
        logger.error("AI response has unexpected shape: %s", json.dumps(data)[:500])
        raise AIRecognitionError(
            "Модель вернула некорректный ответ",
            kind="bad_response",
            raw=json.dumps(data)[:500],
        ) from e

    finish_reason = None
    try:
        finish_reason = data["choices"][0].get("finish_reason")
    except (KeyError, IndexError, TypeError):
        pass

    candidate = _extract_json_candidate(content or "")
    if candidate is None:
        logger.error("AI response has no JSON object. finish_reason=%s content=%r", finish_reason, content[:500])
        raise AIRecognitionError(
            "Модель не вернула JSON",
            kind="no_json",
            raw=content[:500],
        )

    cleaned = _clean_json_text(candidate)

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError as e:
        truncated = finish_reason == "length"
        logger.error(
            "AI JSON decode failed: %s | finish_reason=%s | content=%r",
            e, finish_reason, content[:1000],
        )
        raise AIRecognitionError(
            "Ответ модели не разобрался как JSON"
            + (" (ответ обрезан — превышен лимит токенов)" if truncated else ""),
            kind="truncated" if truncated else "parse_error",
            raw=content[:1000],
        ) from e


async def _post_with_retries(payload: dict) -> dict:
    last_exc: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
                response = await client.post(_ai_url(), headers=_ai_headers(), json=payload)

            if response.status_code >= 500:
                snippet = response.text[:300]
                logger.warning(
                    "Timeweb AI returned %d on attempt %d/%d: %s",
                    response.status_code, attempt, MAX_ATTEMPTS, snippet,
                )
                last_exc = AIRecognitionError(
                    f"AI сервис временно недоступен (HTTP {response.status_code})",
                    kind="upstream_5xx",
                    raw=snippet,
                )
            elif response.status_code == 429:
                snippet = response.text[:300]
                logger.warning(
                    "Timeweb AI rate-limited on attempt %d/%d: %s",
                    attempt, MAX_ATTEMPTS, snippet,
                )
                last_exc = AIRecognitionError(
                    "AI сервис ограничил частоту запросов, попробуйте позже",
                    kind="rate_limited",
                    raw=snippet,
                )
            elif response.status_code >= 400:
                snippet = response.text[:500]
                logger.error(
                    "Timeweb AI returned %d (non-retryable): %s",
                    response.status_code, snippet,
                )
                raise AIRecognitionError(
                    f"AI сервис отклонил запрос (HTTP {response.status_code})",
                    kind="upstream_4xx",
                    raw=snippet,
                )
            else:
                return response.json()
        except (httpx.TimeoutException, httpx.TransportError, httpx.NetworkError) as e:
            logger.warning(
                "Timeweb AI network error on attempt %d/%d: %s: %s",
                attempt, MAX_ATTEMPTS, type(e).__name__, e,
            )
            last_exc = AIRecognitionError(
                "Не удалось связаться с AI сервисом",
                kind="network",
                raw=str(e),
            )

        if attempt < MAX_ATTEMPTS:
            delay = RETRY_BASE_DELAY * (2 ** (attempt - 1))
            await asyncio.sleep(delay)

    assert last_exc is not None
    raise last_exc


async def recognize_food(image_bytes: bytes, *, text: str | None = None) -> dict:
    """Отправляет фото еды в Timeweb Cloud AI-агент для распознавания.

    Если передан text, он используется как сопроводительное описание к фото.
    """
    image_base64 = normalize_image(image_bytes)

    if text:
        user_text = f"Вот фото еды. Описание от пользователя: «{text}». Определи блюдо и его БЖУ. Ответь JSON."
    else:
        user_text = "Определи блюдо на фото и его БЖУ. Ответь JSON."

    payload = {
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{image_base64}"
                        },
                    },
                    {
                        "type": "text",
                        "text": user_text,
                    },
                ],
            },
        ],
        "temperature": 0.2,
        "max_tokens": MAX_TOKENS,
    }

    data = await _post_with_retries(payload)
    return _parse_ai_response(data)


async def recognize_food_from_text(text: str) -> dict:
    """Отправляет текстовое описание еды в Timeweb Cloud AI-агент для оценки КБЖУ."""
    payload = {
        "messages": [
            {"role": "system", "content": TEXT_SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        "temperature": 0.2,
        "max_tokens": MAX_TOKENS,
    }

    data = await _post_with_retries(payload)
    return _parse_ai_response(data)
