import base64
import io
import json
import logging
import re

import httpx
from PIL import Image

from app.config import settings

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """Ты профессиональный диетолог-нутрициолог. Проанализируй фотографию еды и определи:
1. Название блюда
2. Список ингредиентов с примерными граммовками
3. БЖУ и калории на всю порцию и на 100 г

Ответь СТРОГО в формате JSON (без markdown, без текста до/после):
{
  "name": "Название блюда",
  "total_grams": 350,
  "ingredients": [
    {"name": "Ингредиент 1", "grams": 200, "protein": 10.0, "fat": 5.0, "carbs": 20.0, "calories": 165}
  ],
  "per_100g": {"protein": 8.5, "fat": 4.2, "carbs": 15.0, "calories": 132},
  "total": {"protein": 30.0, "fat": 15.0, "carbs": 52.0, "calories": 462}
}"""

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


async def recognize_food(image_bytes: bytes) -> dict:
    """Отправляет фото еды в Timeweb Cloud AI-агент для распознавания."""
    image_base64 = normalize_image(image_bytes)

    url = f"{settings.timeweb_ai_base_url}/{settings.timeweb_ai_agent_id}/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.timeweb_ai_token}",
        "Content-Type": "application/json",
    }
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
                        "text": "Определи блюдо на фото и его БЖУ. Ответь JSON.",
                    },
                ],
            },
        ],
        "temperature": 0.2,
        "max_tokens": 500,
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(url, headers=headers, json=payload)
        response.raise_for_status()

    data = response.json()
    content = data["choices"][0]["message"]["content"]

    json_match = re.search(r"\{.*\}", content, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())

    return json.loads(content)
