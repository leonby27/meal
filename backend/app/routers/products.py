from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.product import Product

router = APIRouter(prefix="/api/products", tags=["products"])


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

    return ProductsListResponse(
        products=[ProductResponse(
            id=p.id, name=p.name, weight_grams=p.weight_grams,
            protein_per_100g=p.protein_per_100g, fat_per_100g=p.fat_per_100g,
            carbs_per_100g=p.carbs_per_100g, calories_per_100g=p.calories_per_100g,
            image_url=p.image_url, brand=p.brand, country=p.country,
            category=p.category,
        ) for p in products],
        total=total,
        page=page,
        page_size=page_size,
    )


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

    return [ProductResponse(
        id=p.id, name=p.name, weight_grams=p.weight_grams,
        protein_per_100g=p.protein_per_100g, fat_per_100g=p.fat_per_100g,
        carbs_per_100g=p.carbs_per_100g, calories_per_100g=p.calories_per_100g,
        image_url=p.image_url, brand=p.brand, country=p.country,
        category=p.category,
    ) for p in products]
