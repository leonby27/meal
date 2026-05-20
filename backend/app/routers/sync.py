from datetime import datetime, date
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.food_log import FoodLog, MealType
from app.routers.deps import get_current_user_id

router = APIRouter(prefix="/api/sync", tags=["sync"])


class FoodLogEntry(BaseModel):
    id: str
    product_id: Optional[int] = None
    product_name: str
    meal_type: MealType
    meal_date: date
    grams: float
    protein: float
    fat: float
    carbs: float
    calories: float
    image_url: Optional[str] = None
    ingredients_json: Optional[str] = None
    # AI-supplied analytics fields — all optional so older clients that
    # don't send them still push successfully.
    health_rating: Optional[int] = None
    health_comment: Optional[str] = None
    meal_quote: Optional[str] = None
    complete_macro_json: Optional[str] = None
    goal_fit_json: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class SyncPushRequest(BaseModel):
    entries: list


class SyncPushResponse(BaseModel):
    synced: int


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(
    req: SyncPushRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    synced = 0
    for entry_data in req.entries:
        entry = FoodLogEntry(**entry_data) if isinstance(entry_data, dict) else entry_data
        existing = await db.execute(
            select(FoodLog).where(
                FoodLog.id == entry.id,
                FoodLog.user_id == user_id,
            )
        )
        log = existing.scalar_one_or_none()

        if log:
            log.product_name = entry.product_name
            log.meal_type = entry.meal_type
            log.meal_date = entry.meal_date
            log.grams = entry.grams
            log.protein = entry.protein
            log.fat = entry.fat
            log.carbs = entry.carbs
            log.calories = entry.calories
            log.image_url = entry.image_url
            log.ingredients_json = entry.ingredients_json
            log.health_rating = entry.health_rating
            log.health_comment = entry.health_comment
            log.meal_quote = entry.meal_quote
            log.complete_macro_json = entry.complete_macro_json
            log.goal_fit_json = entry.goal_fit_json
        else:
            log = FoodLog(
                id=entry.id,
                user_id=user_id,
                product_id=entry.product_id,
                product_name=entry.product_name,
                meal_type=entry.meal_type,
                meal_date=entry.meal_date,
                grams=entry.grams,
                protein=entry.protein,
                fat=entry.fat,
                carbs=entry.carbs,
                calories=entry.calories,
                image_url=entry.image_url,
                ingredients_json=entry.ingredients_json,
                health_rating=entry.health_rating,
                health_comment=entry.health_comment,
                meal_quote=entry.meal_quote,
                complete_macro_json=entry.complete_macro_json,
                goal_fit_json=entry.goal_fit_json,
            )
            db.add(log)
        synced += 1

    await db.commit()
    return SyncPushResponse(synced=synced)


@router.get("/pull")
async def sync_pull(
    since: Optional[datetime] = Query(None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    query = select(FoodLog).where(FoodLog.user_id == user_id)
    if since:
        query = query.where(FoodLog.updated_at > since)
    query = query.order_by(FoodLog.meal_date.desc(), FoodLog.created_at.desc())

    result = await db.execute(query)
    logs = result.scalars().all()

    return [FoodLogEntry(
        id=str(log.id),
        product_id=log.product_id,
        product_name=log.product_name,
        meal_type=log.meal_type,
        meal_date=log.meal_date,
        grams=log.grams,
        protein=log.protein,
        fat=log.fat,
        carbs=log.carbs,
        calories=log.calories,
        image_url=log.image_url,
        ingredients_json=log.ingredients_json,
        health_rating=log.health_rating,
        health_comment=log.health_comment,
        meal_quote=log.meal_quote,
        complete_macro_json=log.complete_macro_json,
        goal_fit_json=log.goal_fit_json,
        created_at=log.created_at,
        updated_at=log.updated_at,
    ) for log in logs]
