import base64
import json
import re

import httpx

from app.config import settings

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


async def recognize_food(image_bytes: bytes) -> dict:
    """Отправляет фото еды в Timeweb Cloud AI-агент для распознавания."""
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")

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
        "temperature": 0.3,
        "max_tokens": 1000,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, headers=headers, json=payload)
        response.raise_for_status()

    data = response.json()
    content = data["choices"][0]["message"]["content"]

    json_match = re.search(r"\{.*\}", content, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())

    return json.loads(content)
