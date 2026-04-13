import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.product import Product
from app.services import openfoodfacts

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/products", tags=["products"])


def _product_to_response(p: Product) -> "ProductResponse":
    return ProductResponse(
        id=p.id, name=p.name, weight_grams=p.weight_grams,
        protein_per_100g=p.protein_per_100g, fat_per_100g=p.fat_per_100g,
        carbs_per_100g=p.carbs_per_100g, calories_per_100g=p.calories_per_100g,
        image_url=p.image_url, brand=p.brand, country=p.country,
        category=p.category, barcode=p.barcode, source=p.source,
    )


class ProductResponse(BaseModel):
    id: int
    name: str
    weight_grams: Optional[float] = None
    protein_per_100g: Optional[float] = None
    fat_per_100g: Optional[float] = None
    carbs_per_100g: Optional[float] = None
    calories_per_100g: Optional[float] = None
    image_url: Optional[str] = None
    brand: Optional[str] = None
    country: Optional[str] = None
    category: Optional[str] = None
    barcode: Optional[str] = None
    source: Optional[str] = None


class ProductsListResponse(BaseModel):
    products: list
    total: int
    page: int
    page_size: int


@router.get("", response_model=ProductsListResponse)
async def list_products(
    search: Optional[str] = Query(None, min_length=2),
    category: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    locale: str = Query("en"),
    db: AsyncSession = Depends(get_db),
):
    query = select(Product)

    if search:
        query = query.where(Product.name.ilike(f"%{search}%"))
    if category:
        query = query.where(Product.category.ilike(f"%{category}%"))

    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    products = result.scalars().all()
    response_list = [_product_to_response(p) for p in products]

    if search and len(response_list) < page_size:
        try:
            off_results = await openfoodfacts.search_products(
                search, page=1, page_size=page_size - len(response_list), locale=locale,
            )
            existing_barcodes = {p.barcode for p in response_list if p.barcode}
            existing_names = {p.name.lower() for p in response_list}
            for item in off_results:
                bc = item.get("barcode")
                if bc and bc in existing_barcodes:
                    continue
                if item["name"].lower() in existing_names:
                    continue
                response_list.append(_off_dict_to_response(item))
                if bc:
                    existing_barcodes.add(bc)
                existing_names.add(item["name"].lower())
        except Exception:
            logger.exception("Failed to supplement search with OFF results")

    return ProductsListResponse(
        products=response_list,
        total=total + max(0, len(response_list) - len(products)),
        page=page,
        page_size=page_size,
    )


async def _cache_off_product(data: dict, db: AsyncSession) -> Product:
    """Save an OpenFoodFacts product dict to PostgreSQL and return the ORM object."""
    product = Product(
        name=data["name"],
        weight_grams=data.get("weight_grams"),
        protein_per_100g=data.get("protein_per_100g"),
        fat_per_100g=data.get("fat_per_100g"),
        carbs_per_100g=data.get("carbs_per_100g"),
        calories_per_100g=data.get("calories_per_100g"),
        image_url=data.get("image_url"),
        brand=data.get("brand"),
        country=data.get("country"),
        category=data.get("category"),
        composition=data.get("composition"),
        barcode=data.get("barcode"),
        source="openfoodfacts",
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


def _off_dict_to_response(data: dict) -> ProductResponse:
    return ProductResponse(
        id=0,
        name=data["name"],
        weight_grams=data.get("weight_grams"),
        protein_per_100g=data.get("protein_per_100g"),
        fat_per_100g=data.get("fat_per_100g"),
        carbs_per_100g=data.get("carbs_per_100g"),
        calories_per_100g=data.get("calories_per_100g"),
        image_url=data.get("image_url"),
        brand=data.get("brand"),
        country=data.get("country"),
        category=data.get("category"),
        barcode=data.get("barcode"),
        source="openfoodfacts",
    )


@router.get("/barcode/{barcode}")
async def get_by_barcode(
    barcode: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Product).where(Product.barcode == barcode).limit(1)
    )
    existing = result.scalar_one_or_none()
    if existing:
        return _product_to_response(existing)

    off_data = await openfoodfacts.get_by_barcode(barcode)
    if not off_data:
        raise HTTPException(status_code=404, detail="Product not found")

    cached = await _cache_off_product(off_data, db)
    return _product_to_response(cached)


@router.get("/updates")
async def get_updates(
    since: Optional[datetime] = None,
    db: AsyncSession = Depends(get_db),
):
    """Returns products added/updated after `since` timestamp."""
    query = select(Product)
    if since:
        query = query.where(Product.created_at > since)
    query = query.order_by(Product.created_at.desc()).limit(500)

    result = await db.execute(query)
    products = result.scalars().all()

    return [_product_to_response(p) for p in products]
