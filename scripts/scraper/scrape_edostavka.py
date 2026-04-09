#!/usr/bin/env python3
"""
Парсер edostavka.by — сбор готовых к употреблению продуктов с БЖУ и калориями.

Стратегия:
1. Обход категорий по whitelist (только готовые к употреблению продукты)
2. Сбор ID продуктов из листингов категорий (пагинация через __NEXT_DATA__)
3. Загрузка детальной информации для каждого продукта (БЖУ из customPropertyGroup)
4. Сохранение в SQLite базу данных
"""

import json
import re
import sqlite3
import sys
import time
from pathlib import Path
from typing import Optional
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

BASE_URL = "https://edostavka.by"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "ru-RU,ru;q=0.9",
}

CATEGORY_WHITELIST = {
    5194: "Молоко, яйца",
    5329: "Хлеб, выпечка",
    4974: "Еда от Шефа",
    5309: "Вода, напитки",
    5091: "Чипсы, орехи, снеки",
    5160: "Сладости",
    4996: "Здоровое питание",
    5150: "Кофе, чай",
}

SUBCATEGORY_WHITELIST = {
    # Из "Мясо, птица, колбасы" (5131) — только готовые
    5645: "Мясные изделия",
    5611: "Колбасные изделия",

    # Из "Рыба, морепродукты" (5185) — только готовые
    5247: "Рыба готовая",
    4980: "Икра",

    # Из "Масло, консервация, соусы" (5199) — только готовые
    5256: "Кетчупы, соусы",
    5650: "Консервы рыбные и мясные",
    5648: "Овощи, грибы консервированные",
    5620: "Сладкая консервация",
    5635: "Квашения, соления",
    5607: "Готовые салаты, полуфабрикаты",

    # Из "Овощи и фрукты" (5138) — только те что едят сырыми
    5292: "Фрукты",
    5328: "Ягоды",
    4985: "Зелень",
    5515: "Квашения, соления, салаты",

    # Из "Детские товары" (5045) — только питание
    5136: "Смеси, каши",
    5196: "Консервы, пюре",
    5082: "Вода, соки, напитки (детские)",
    5245: "Бакалея детская",
}

NUTRITION_PROPERTY_IDS = {
    307: "protein",
    308: "fat",
    317: "carbs",
    313: "energy",
}

DB_PATH = Path(__file__).parent.parent.parent / "assets" / "database" / "products.db"

session = requests.Session()
session.headers.update(HEADERS)


def extract_next_data(html: str) -> Optional[dict]:
    match = re.search(r'__NEXT_DATA__[^>]*>(.*?)</script>', html)
    if not match:
        return None
    try:
        return json.loads(match.group(1))
    except json.JSONDecodeError:
        return None


def get_category_products(category_id: int, category_name: str) -> list[int]:
    """Собирает все product IDs из категории (все страницы)."""
    product_ids = []
    page = 1

    while True:
        url = f"{BASE_URL}/category/{category_id}?page={page}"
        try:
            resp = session.get(url, timeout=15)
            resp.raise_for_status()
        except requests.RequestException as e:
            print(f"  [ERROR] {url}: {e}")
            break

        data = extract_next_data(resp.text)
        if not data:
            print(f"  [ERROR] No __NEXT_DATA__ for category {category_id} page {page}")
            break

        listing = data.get("props", {}).get("pageProps", {}).get("listing", {})
        products = listing.get("products", [])
        page_amount = listing.get("pageAmount", 1)

        for p in products:
            pid = p.get("productId")
            if pid:
                product_ids.append(pid)

        print(f"  [{category_name}] Страница {page}/{page_amount}: {len(products)} продуктов")

        if page >= page_amount:
            break
        page += 1
        time.sleep(0.3)

    return product_ids


def get_product_detail(product_id: int) -> Optional[dict]:
    """Загружает детальную информацию о продукте, включая БЖУ."""
    url = f"{BASE_URL}/product/{product_id}"
    try:
        resp = session.get(url, timeout=15)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"  [ERROR] Product {product_id}: {e}")
        return None

    data = extract_next_data(resp.text)
    if not data:
        return None

    product = (
        data.get("props", {})
        .get("pageProps", {})
        .get("productData", {})
        .get("product", {})
    )
    if not product or not product.get("productId"):
        return None

    nutrition = {}
    for prop in product.get("customPropertyGroup", []):
        prop_id = prop.get("propertyId")
        values = prop.get("propertyValue", [])
        if prop_id in NUTRITION_PROPERTY_IDS and values:
            nutrition[NUTRITION_PROPERTY_IDS[prop_id]] = values[0]

    weight = None
    for prop in product.get("previewProperties", []):
        if prop.get("propertyName", "").strip().startswith("Вес"):
            vals = prop.get("propertyValue", [])
            if vals:
                weight = vals[0]
            break

    images = product.get("images", [])
    image_url = images[0] if images else None

    brand = product.get("legalInfo", {}).get("trademarkName", "")
    country = product.get("legalInfo", {}).get("countryOfManufacture", "")

    breadcrumbs = product.get("breadCrumbs", [])
    category_path = ""
    if breadcrumbs:
        parts = [breadcrumbs[0].get("categoryListName", "")]
        for sub in breadcrumbs[0].get("categories", []):
            parts.append(sub.get("categoryListName", ""))
            for sub2 in sub.get("categories", []):
                parts.append(sub2.get("categoryListName", ""))
        category_path = " > ".join(p for p in parts if p)

    protein = parse_number(nutrition.get("protein"))
    fat = parse_number(nutrition.get("fat"))
    carbs = parse_number(nutrition.get("carbs"))
    calories = parse_calories(nutrition.get("energy"))

    composition = product.get("description", {}).get("composition", "")

    return {
        "product_id": product.get("productId"),
        "name": product.get("productName", ""),
        "weight_grams": parse_number(weight),
        "protein_per_100g": protein,
        "fat_per_100g": fat,
        "carbs_per_100g": carbs,
        "calories_per_100g": calories,
        "image_url": image_url,
        "brand": brand,
        "country": country,
        "category": category_path,
        "composition": composition,
        "price": product.get("price", {}).get("discountedPrice", 0),
    }


def parse_number(value: Optional[str]) -> Optional[float]:
    if not value:
        return None
    cleaned = re.sub(r"[^\d.,]", "", str(value).replace(",", "."))
    try:
        return float(cleaned)
    except (ValueError, TypeError):
        return None


def parse_calories(value: Optional[str]) -> Optional[float]:
    if not value:
        return None
    match = re.search(r"(\d+[.,]?\d*)\s*ккал", str(value))
    if match:
        return float(match.group(1).replace(",", "."))
    return parse_number(value)


def init_database(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.execute("""
        CREATE TABLE IF NOT EXISTS products (
            product_id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            weight_grams REAL,
            protein_per_100g REAL,
            fat_per_100g REAL,
            carbs_per_100g REAL,
            calories_per_100g REAL,
            image_url TEXT,
            brand TEXT,
            country TEXT,
            category TEXT,
            composition TEXT,
            price REAL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)
    """)
    conn.commit()
    return conn


def save_product(conn: sqlite3.Connection, product: dict):
    conn.execute("""
        INSERT OR REPLACE INTO products
        (product_id, name, weight_grams, protein_per_100g, fat_per_100g,
         carbs_per_100g, calories_per_100g, image_url, brand, country,
         category, composition, price)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        product["product_id"],
        product["name"],
        product["weight_grams"],
        product["protein_per_100g"],
        product["fat_per_100g"],
        product["carbs_per_100g"],
        product["calories_per_100g"],
        product["image_url"],
        product["brand"],
        product["country"],
        product["category"],
        product["composition"],
        product["price"],
    ))


def fetch_product_with_delay(product_id: int) -> Optional[dict]:
    time.sleep(0.15)
    return get_product_detail(product_id)


def get_leaf_subcategories(category_id: int) -> list[tuple[int, str]]:
    """Рекурсивно собирает все leaf-подкатегории из верхнеуровневой категории."""
    url = f"{BASE_URL}/category/{category_id}"
    try:
        resp = session.get(url, timeout=15)
        resp.raise_for_status()
    except requests.RequestException as e:
        print(f"  [ERROR] Subcategory fetch {category_id}: {e}", flush=True)
        return [(category_id, f"cat_{category_id}")]

    data = extract_next_data(resp.text)
    if not data:
        return [(category_id, f"cat_{category_id}")]

    cats_tree = (
        data.get("props", {}).get("pageProps", {})
        .get("listing", {}).get("categories", [])
    )
    if not cats_tree:
        return [(category_id, f"cat_{category_id}")]

    def collect(nodes):
        leaves = []
        for node in nodes:
            children = node.get("categories", [])
            if children:
                leaves.extend(collect(children))
            else:
                cid = node.get("categoryListId")
                name = node.get("categoryListName", "")
                if cid:
                    leaves.append((cid, name))
        return leaves

    root_children = cats_tree[0].get("categories", []) if cats_tree else []
    leaves = collect(root_children)
    return leaves if leaves else [(category_id, f"cat_{category_id}")]


def main():
    sys.stdout.reconfigure(line_buffering=True) if hasattr(sys.stdout, 'reconfigure') else None
    print("=" * 60, flush=True)
    print("Парсер edostavka.by — готовые к употреблению продукты", flush=True)
    print("=" * 60, flush=True)

    resolved_categories = {}

    print("\nРазворачиваю подкатегории из whitelist...", flush=True)
    for cat_id, cat_name in CATEGORY_WHITELIST.items():
        print(f"  [{cat_name}] (ID: {cat_id})...", flush=True)
        leaves = get_leaf_subcategories(cat_id)
        for lid, lname in leaves:
            resolved_categories[lid] = f"{cat_name} > {lname}"
        print(f"    → {len(leaves)} подкатегорий", flush=True)
        time.sleep(0.3)

    for cat_id, cat_name in SUBCATEGORY_WHITELIST.items():
        resolved_categories[cat_id] = cat_name

    print(f"\nВсего категорий для обхода: {len(resolved_categories)}", flush=True)
    print("-" * 60, flush=True)

    all_product_ids = set()

    for cat_id, cat_name in resolved_categories.items():
        print(f"\n[{cat_name}] (ID: {cat_id})", flush=True)
        ids = get_category_products(cat_id, cat_name)
        new_ids = set(ids) - all_product_ids
        all_product_ids.update(ids)
        print(f"  Найдено: {len(ids)}, новых: {len(new_ids)}", flush=True)
        time.sleep(0.5)

    print(f"\n{'=' * 60}")
    print(f"Всего уникальных продуктов для загрузки: {len(all_product_ids)}")
    print(f"{'=' * 60}")

    conn = init_database(DB_PATH)
    print(f"\nБаза данных: {DB_PATH}")

    product_ids_list = sorted(all_product_ids)
    total = len(product_ids_list)
    saved = 0
    skipped_no_nutrition = 0
    errors = 0

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {}
        for pid in product_ids_list:
            future = executor.submit(fetch_product_with_delay, pid)
            futures[future] = pid

        for i, future in enumerate(as_completed(futures), 1):
            pid = futures[future]
            try:
                product = future.result()
                if product and product.get("calories_per_100g") is not None:
                    save_product(conn, product)
                    saved += 1
                elif product:
                    skipped_no_nutrition += 1
                else:
                    errors += 1
            except Exception as e:
                print(f"  [ERROR] Product {pid}: {e}")
                errors += 1

            if i % 50 == 0 or i == total:
                conn.commit()
                print(f"  Прогресс: {i}/{total} | Сохранено: {saved} | "
                      f"Без БЖУ: {skipped_no_nutrition} | Ошибок: {errors}")

    conn.commit()

    cursor = conn.execute("SELECT COUNT(*) FROM products")
    db_count = cursor.fetchone()[0]

    print(f"\n{'=' * 60}")
    print(f"ГОТОВО!")
    print(f"Продуктов в базе: {db_count}")
    print(f"Сохранено: {saved}")
    print(f"Пропущено (нет БЖУ): {skipped_no_nutrition}")
    print(f"Ошибок: {errors}")
    print(f"База данных: {DB_PATH}")
    print(f"{'=' * 60}")

    conn.close()


if __name__ == "__main__":
    main()
