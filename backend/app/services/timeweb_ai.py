import asyncio
import base64
import copy
import io
import json
import logging
import re

import httpx
from PIL import Image, ImageOps

from app.config import settings
from app.services import openfoodfacts

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
# client asks for in the prompt. The parser also accepts English "pc(s)" /
# "piece(s)" for resilience if the model localises the marker anyway.
_COMMON_RULES_EN = """Recognition and ingredient formatting rules:
- If the user supplied a textual description together with the photo, treat
  explicit facts from that text as authoritative: dish name, weight, count,
  ingredients, "without oil/sauce/sugar", cooking method, etc. Use the image
  to fill missing details, not to override explicit user facts.
- Estimate portion size from visible cues: plate/container size, utensils,
  hand/fork/spoon scale, packaging, cut pieces, and how full the container is.
  If there is no reliable scale reference, use a common serving size for that
  dish and keep the estimate realistic.
- For photos with multiple edible items in the same serving, include all
  visible items. Do not include non-edible items, decorations, packaging, or
  food that is not visible unless the user explicitly mentions it.
- If the photo shows separate foods/products rather than one prepared dish,
  name it as a selection/plate of items and list each visible edible item
  separately. Do not collapse separate packaged snacks and sliced meat into a
  single dish name like "salami with cheese" unless they are actually combined.
- For packaged foods, first read any visible label/brand/product text and use
  that over visual guessing. Preserve readable brand or product names in the
  ingredient name when helpful (for example, a visible candy bar, protein bar,
  glazed cottage cheese bar, yogurt, or packaged snack).
- Do not confidently infer a specific product subtype from package shape alone
  (for example "processed cheese", "cottage cheese bar", "protein bar",
  "candy bar"). Use that subtype only when the label is readable or the visual
  evidence is very strong. If uncertain, use a neutral category such as
  "packaged dairy dessert", "packaged snack bar", or "packaged sweet bar".
- For mixed dishes (soups, salads, pasta, bowls, stews, sandwiches, sauces),
  estimate the main components at a practical level of detail. Do not invent
  many tiny hidden ingredients; include modest amounts of common oil, dressing,
  sauce, or sugar only when visually likely or mentioned.
- Round weights and nutrition to realistic precision. Avoid fake exactness:
  grams are usually rounded to 5-10 g, calories to whole numbers, macros to
  one decimal place when needed.
- `total_grams` must approximately equal the sum of ingredient `grams`.
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
PACKAGED_ENRICH_TIMEOUT = 2.0
PACKAGED_ENRICH_MAX_ITEMS = 3

_PACKAGED_KEYWORDS = {
    "packaged", "package", "wrapper", "wrapped", "bar", "snack", "candy",
    "упаков", "батончик", "снэк", "снек", "сырок", "творож", "глазирован",
}

_GENERIC_MATCH_TOKENS = {
    "packaged", "package", "wrapper", "wrapped", "bar", "snack", "sweet",
    "dairy", "dessert", "продукт", "упаковка", "упакованный", "сладкий",
    "молочный", "десерт", "батончик", "сырок",
}


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


def _locale_code(locale: str | None) -> str:
    if not locale:
        return "en"
    return locale.lower().split("-")[0].split("_")[0] or "en"


def _normalise_product_text(value: str) -> str:
    value = re.sub(r"\(\d+\s*(?:шт\.?|pcs?\.?|pieces?)\)", " ", value, flags=re.IGNORECASE)
    value = value.lower()
    value = re.sub(r"[^0-9a-zа-яё]+", " ", value, flags=re.IGNORECASE)
    return re.sub(r"\s+", " ", value).strip()


def _tokens(value: str) -> set[str]:
    return {
        token
        for token in _normalise_product_text(value).split()
        if len(token) >= 3 and token not in _GENERIC_MATCH_TOKENS
    }


def _looks_like_packaged_item(name: str) -> bool:
    normalised = _normalise_product_text(name)
    if any(keyword in normalised for keyword in _PACKAGED_KEYWORDS):
        return True

    # Visible package labels often contain a short latin brand/product token
    # plus a flavour/count token (e.g. "TOM x2 coconut"). Avoid searching for
    # plain unpackaged foods like "salami" or "rice".
    latin_tokens = re.findall(r"\b[a-z0-9]{2,}\b", normalised)
    return len(latin_tokens) >= 2 and any(char.isdigit() for char in normalised)


def _product_match_score(query: str, product: dict) -> float:
    product_text = " ".join(
        str(part or "")
        for part in (
            product.get("brand"),
            product.get("name"),
            product.get("category"),
            product.get("composition"),
        )
    )
    query_tokens = _tokens(query)
    product_tokens = _tokens(product_text)
    if not query_tokens or not product_tokens:
        return 0.0

    overlap = query_tokens & product_tokens
    score = len(overlap) / len(query_tokens)
    query_norm = _normalise_product_text(query)
    product_norm = _normalise_product_text(product_text)
    if query_norm and query_norm in product_norm:
        score += 0.35
    if product.get("brand") and _normalise_product_text(str(product["brand"])) in query_norm:
        score += 0.15
    return score


async def _find_packaged_product(query: str, locale: str | None) -> dict | None:
    try:
        products = await asyncio.wait_for(
            openfoodfacts.search_products(
                query,
                page=1,
                page_size=5,
                locale=_locale_code(locale),
            ),
            timeout=PACKAGED_ENRICH_TIMEOUT,
        )
    except Exception as e:
        logger.info("OFF packaged enrichment skipped for query=%r: %s", query, e)
        return None

    scored = [
        (_product_match_score(query, product), product)
        for product in products
    ]
    scored.sort(key=lambda item: item[0], reverse=True)
    if not scored or scored[0][0] < 0.45:
        return None
    return scored[0][1]


def _apply_product_nutrition(ingredient: dict, product: dict) -> bool:
    calories = product.get("calories_per_100g")
    if calories is None:
        return False

    grams = (ingredient.get("grams") or 0) or product.get("weight_grams") or 100
    try:
        grams = float(grams)
    except (TypeError, ValueError):
        grams = 100.0
    if grams <= 0:
        grams = 100.0

    factor = grams / 100.0
    ingredient["grams"] = round(grams, 1)
    ingredient["calories"] = round(float(calories) * factor)

    for source_key, target_key in (
        ("protein_per_100g", "protein"),
        ("fat_per_100g", "fat"),
        ("carbs_per_100g", "carbs"),
    ):
        value = product.get(source_key)
        if value is not None:
            ingredient[target_key] = round(float(value) * factor, 1)

    product_name = product.get("name")
    brand = product.get("brand")
    if product_name:
        full_name = f"{brand} {product_name}".strip() if brand else product_name
        ingredient["name"] = full_name

    return True


def _recalculate_totals(result: dict) -> None:
    ingredients = result.get("ingredients") or []
    total_grams = sum(float(i.get("grams") or 0) for i in ingredients)
    totals = {
        "protein": sum(float(i.get("protein") or 0) for i in ingredients),
        "fat": sum(float(i.get("fat") or 0) for i in ingredients),
        "carbs": sum(float(i.get("carbs") or 0) for i in ingredients),
        "calories": sum(float(i.get("calories") or 0) for i in ingredients),
    }

    result["total_grams"] = round(total_grams, 1)
    result["total"] = {
        "protein": round(totals["protein"], 1),
        "fat": round(totals["fat"], 1),
        "carbs": round(totals["carbs"], 1),
        "calories": round(totals["calories"]),
    }
    if total_grams > 0:
        result["per_100g"] = {
            "protein": round(totals["protein"] / total_grams * 100, 1),
            "fat": round(totals["fat"] / total_grams * 100, 1),
            "carbs": round(totals["carbs"] / total_grams * 100, 1),
            "calories": round(totals["calories"] / total_grams * 100),
        }


async def _enrich_packaged_items(result: dict, locale: str | None) -> dict:
    ingredients = result.get("ingredients")
    if not isinstance(ingredients, list):
        return result

    candidates = [
        (index, str(item.get("name") or ""))
        for index, item in enumerate(ingredients)
        if isinstance(item, dict) and _looks_like_packaged_item(str(item.get("name") or ""))
    ][:PACKAGED_ENRICH_MAX_ITEMS]
    if not candidates:
        return result

    enriched = copy.deepcopy(result)
    matches = await asyncio.gather(
        *(_find_packaged_product(query, locale) for _, query in candidates),
        return_exceptions=True,
    )

    changed = False
    for (index, query), match in zip(candidates, matches):
        if isinstance(match, Exception) or not match:
            continue
        if _apply_product_nutrition(enriched["ingredients"][index], match):
            changed = True
            logger.info(
                "OFF packaged enrichment matched query=%r to product=%r",
                query,
                match.get("name"),
            )

    if changed:
        _recalculate_totals(enriched)
        return enriched
    return result


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
            f"Use explicit facts from the description as authoritative. "
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
    result = _parse_ai_response(data)
    return await _enrich_packaged_items(result, locale)


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
