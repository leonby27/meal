import logging
import re
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

_SEARCH_URL = "https://world.openfoodfacts.org/cgi/search.pl"
_PRODUCT_URL = "https://world.openfoodfacts.org/api/v2/product"
_TIMEOUT = 5.0
_USER_AGENT = "MealTracker/1.0 (https://github.com/mealtracker)"

_PRODUCT_FIELDS = (
    "code,product_name,brands,countries_tags,categories_tags,"
    "nutriments,quantity,image_front_small_url,image_front_url,"
    "ingredients_text"
)


def _parse_weight(quantity: Optional[str]) -> Optional[float]:
    """Extract grams from quantity strings like '250 g', '1.5 kg', '330 ml'."""
    if not quantity:
        return None
    m = re.search(r"([\d.,]+)\s*(g|г|kg|кг|ml|мл|l|л)", quantity, re.IGNORECASE)
    if not m:
        return None
    value = float(m.group(1).replace(",", "."))
    unit = m.group(2).lower()
    if unit in ("kg", "кг"):
        value *= 1000
    elif unit in ("l", "л"):
        value *= 1000
    return value


def _map_product(p: dict) -> Optional[dict]:
    """Map an OFF product dict to our internal schema. Returns None if unusable."""
    name = p.get("product_name", "").strip()
    if not name:
        return None

    n = p.get("nutriments", {})
    calories = n.get("energy-kcal_100g")
    if calories is None:
        energy_kj = n.get("energy_100g")
        if energy_kj is not None:
            calories = round(energy_kj / 4.184, 1)

    if calories is None:
        return None

    return {
        "barcode": p.get("code"),
        "name": name,
        "weight_grams": _parse_weight(p.get("quantity")),
        "protein_per_100g": n.get("proteins_100g"),
        "fat_per_100g": n.get("fat_100g"),
        "carbs_per_100g": n.get("carbohydrates_100g"),
        "calories_per_100g": calories,
        "image_url": p.get("image_front_small_url") or p.get("image_front_url"),
        "brand": p.get("brands", "").strip() or None,
        "country": None,
        "category": ", ".join(
            t.replace("en:", "") for t in (p.get("categories_tags") or [])[:3]
        ) or None,
        "composition": p.get("ingredients_text") or None,
        "source": "openfoodfacts",
    }


async def search_products(
    query: str, page: int = 1, page_size: int = 50, locale: str = "en"
) -> list[dict]:
    params = {
        "search_terms": query,
        "search_simple": "1",
        "action": "process",
        "json": "1",
        "page": str(page),
        "page_size": str(page_size),
        "fields": _PRODUCT_FIELDS,
        "lc": locale,
    }
    headers = {"User-Agent": _USER_AGENT}

    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.get(_SEARCH_URL, params=params, headers=headers)
            resp.raise_for_status()
            data = resp.json()
    except Exception:
        logger.exception("OFF search failed for query=%s", query)
        return []

    results = []
    for p in data.get("products", []):
        mapped = _map_product(p)
        if mapped:
            results.append(mapped)
    return results


async def get_by_barcode(barcode: str) -> Optional[dict]:
    url = f"{_PRODUCT_URL}/{barcode}"
    params = {"fields": _PRODUCT_FIELDS}
    headers = {"User-Agent": _USER_AGENT}

    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            resp = await client.get(url, params=params, headers=headers)
            if resp.status_code == 404:
                return None
            resp.raise_for_status()
            data = resp.json()
    except Exception:
        logger.exception("OFF barcode lookup failed for barcode=%s", barcode)
        return None

    if data.get("status") != 1:
        return None

    return _map_product(data.get("product", {}))
