import asyncio
import base64
import io
import json
import logging
import re

import httpx
from PIL import Image, ImageOps

from app.config import settings

logger = logging.getLogger(__name__)

_JSON_SCHEMA = """{
  "name": "Dish name",
  "total_grams": 350,
  "ingredients": [
    {"name": "Chicken egg (2 шт.)", "grams": 110, "protein": 14.0, "fat": 11.0, "carbs": 0.8, "calories": 155},
    {"name": "Tomatoes", "grams": 80, "protein": 0.9, "fat": 0.2, "carbs": 3.2, "calories": 18},
    {"name": "Hard cheese", "grams": 30, "protein": 7.5, "fat": 8.4, "carbs": 0.0, "calories": 105}
  ],
  "per_100g": {"protein": 10.5, "fat": 8.5, "carbs": 2.2, "calories": 127},
  "total": {"protein": 22.4, "fat": 19.6, "carbs": 4.0, "calories": 278}
}"""

# BCP-47 / ISO 639-1 language code → full English language name.
# Used to explicitly tell the model which language to respond in.
# Everything the model produces for the user (dish name, ingredient
# names) must be in this language; only the "(N шт.)" piece-count
# marker stays constant across languages so the client-side regex
# (see ai_meal_result_sheet.dart: RegExp(r'\((\d+)\s*шт\.?\)')) still
# matches regardless of UI language.
_LANGUAGE_NAMES = {
    "ru": "Russian",
    "en": "English",
    "de": "German",
    "es": "Spanish",
    "fr": "French",
    "pt": "Portuguese",
}


def _language_name(locale: str | None) -> str:
    if not locale:
        return "Russian"
    code = locale.lower().split("-")[0].split("_")[0]
    return _LANGUAGE_NAMES.get(code, "English")


# Shared rules used by both the image and text prompts.
#
# IMPORTANT — piece-count format:
# For countable ingredients (eggs, sausages, cutlets, meatballs, shrimp,
# dumplings, cookies, slices of bread/pizza, etc.) the client parses
# "(N шт.)" out of the `name` field via regex r'\((\d+)\s*шт\.?\)' and shows
# a +/- stepper so the user can tweak the count. When the stepper is used,
# the client assumes `grams` = total weight for ALL pieces, and computes
# per-unit grams as grams / N.
#
# The "шт." suffix is Cyrillic on purpose and is the ONLY format the
# client currently recognises — do not localise it to "pcs" / "units"
# / etc., or the stepper will never appear for non-Russian UI locales.
_COMMON_RULES_EN = """Ingredient formatting rules:
- For countable ingredients (eggs, sausages, cutlets, meatballs, shrimp,
  dumplings, cookies, slices of bread/pizza, etc.) append "(N шт.)" to
  the `name`, where N is the integer number of pieces. The literal
  characters "шт." (Cyrillic) MUST be used verbatim regardless of the
  response language — the client parses this exact marker to show a
  +/- stepper. Put the TOTAL combined weight of all pieces into
  `grams`. Example: {"name": "Chicken egg (2 шт.)", "grams": 110}.
- For bulk / non-countable ingredients (sauce, oil, grated cheese,
  lettuce, rice, pasta, minced meat, chopped vegetables, etc.) do NOT
  add "(N шт.)" — just use the name and weight in grams.
- Compute protein / fat / carbs / calories for EACH ingredient
  separately so the client can re-total when the user changes piece
  counts.
- `total` must equal the sum across ingredients (within 1–2%).

Respond STRICTLY as JSON (no markdown, no text before or after):
""" + _JSON_SCHEMA

_IMAGE_TASK_EN = """You are a professional dietitian / nutritionist. Analyse the food photograph and determine:
1. Dish name
2. Ingredient list with approximate weights
3. Protein / fat / carbs / calories for the whole portion and per 100 g"""

_TEXT_TASK_EN = """You are a professional dietitian / nutritionist. From the user's textual description of food, determine:
1. Dish name
2. Ingredient list with approximate weights
3. Protein / fat / carbs / calories for the whole portion and per 100 g

If the user gave an explicit weight — use it. Otherwise estimate a
standard portion."""


def build_image_prompt(locale: str | None) -> str:
    lang = _language_name(locale)
    return (
        f"{_IMAGE_TASK_EN}\n\n"
        f"Respond entirely in {lang}. All dish names, ingredient names and "
        f"any free-form text you produce must be in {lang}. The only "
        f"exception is the literal Cyrillic \"шт.\" marker described below, "
        f"which stays the same in every language.\n\n"
        f"{_COMMON_RULES_EN}"
    )


def build_text_prompt(locale: str | None) -> str:
    lang = _language_name(locale)
    return (
        f"{_TEXT_TASK_EN}\n\n"
        f"Respond entirely in {lang}. All dish names, ingredient names and "
        f"any free-form text you produce must be in {lang}. The only "
        f"exception is the literal Cyrillic \"шт.\" marker described below, "
        f"which stays the same in every language.\n\n"
        f"{_COMMON_RULES_EN}"
    )

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
    img = ImageOps.exif_transpose(img)

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


async def recognize_food(
    image_bytes: bytes,
    *,
    text: str | None = None,
    locale: str | None = None,
) -> dict:
    """Отправляет фото еды в Timeweb Cloud AI-агент для распознавания.

    Если передан text, он используется как сопроводительное описание к фото.
    locale — код языка UI (ru/en/de/es/fr/pt); модель должна отвечать именно на нём.
    """
    image_base64 = normalize_image(image_bytes)
    lang = _language_name(locale)

    if text:
        user_text = (
            f"Here is a photo of food. User-provided description: \"{text}\". "
            f"Identify the dish and its nutrition. Reply as JSON, in {lang}."
        )
    else:
        user_text = (
            f"Identify the dish in the photo and its nutrition. "
            f"Reply as JSON, in {lang}."
        )

    payload = {
        "messages": [
            {"role": "system", "content": build_image_prompt(locale)},
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


async def recognize_food_from_text(
    text: str,
    *,
    locale: str | None = None,
) -> dict:
    """Отправляет текстовое описание еды в Timeweb Cloud AI-агент для оценки КБЖУ.

    locale — код языка UI (ru/en/de/es/fr/pt); модель должна отвечать именно на нём.
    """
    lang = _language_name(locale)
    user_text = (
        f"User description of the food: \"{text}\".\n"
        f"Identify the dish and its nutrition. Reply as JSON, in {lang}."
    )
    payload = {
        "messages": [
            {"role": "system", "content": build_text_prompt(locale)},
            {"role": "user", "content": user_text},
        ],
        "temperature": 0.2,
        "max_tokens": MAX_TOKENS,
    }

    data = await _post_with_retries(payload)
    return _parse_ai_response(data)
