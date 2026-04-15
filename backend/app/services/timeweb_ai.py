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
    {"name": "Ингредиент 1", "grams": 200, "protein": 10.0, "fat": 5.0, "carbs": 20.0, "calories": 165}
  ],
  "per_100g": {"protein": 8.5, "fat": 4.2, "carbs": 15.0, "calories": 132},
  "total": {"protein": 30.0, "fat": 15.0, "carbs": 52.0, "calories": 462}
}"""

SYSTEM_PROMPT = f"""Ты профессиональный диетолог-нутрициолог. Проанализируй фотографию еды и определи:
1. Название блюда
2. Список ингредиентов с примерными граммовками
3. БЖУ и калории на всю порцию и на 100 г

Ответь СТРОГО в формате JSON (без markdown, без текста до/после):
{_JSON_SCHEMA}"""

TEXT_SYSTEM_PROMPT = f"""Ты профессиональный диетолог-нутрициолог. По текстовому описанию еды определи:
1. Название блюда
2. Список ингредиентов с примерными граммовками
3. БЖУ и калории на всю порцию и на 100 г

Если пользователь указал граммовку — используй её. Если нет — оцени стандартную порцию.

Ответь СТРОГО в формате JSON (без markdown, без текста до/после):
{_JSON_SCHEMA}"""

MAX_DIMENSION = 512
JPEG_QUALITY = 60


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


def _parse_ai_response(data: dict) -> dict:
    content = data["choices"][0]["message"]["content"]
    json_match = re.search(r"\{.*\}", content, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())
    return json.loads(content)


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
        "max_tokens": 500,
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(_ai_url(), headers=_ai_headers(), json=payload)
        response.raise_for_status()

    return _parse_ai_response(response.json())


async def recognize_food_from_text(text: str) -> dict:
    """Отправляет текстовое описание еды в Timeweb Cloud AI-агент для оценки КБЖУ."""
    payload = {
        "messages": [
            {"role": "system", "content": TEXT_SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        "temperature": 0.2,
        "max_tokens": 500,
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(_ai_url(), headers=_ai_headers(), json=payload)
        response.raise_for_status()

    return _parse_ai_response(response.json())
