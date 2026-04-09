import uuid
from datetime import datetime, date

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
    product_id: int | None = None
    product_name: str
    meal_type: MealType
    meal_date: date
    grams: float
    protein: float
    fat: float
    carbs: float
    calories: float
    created_at: datetime | None = None
    updated_at: datetime | None = None


class SyncPushRequest(BaseModel):
    entries: list[FoodLogEntry]


class SyncPushResponse(BaseModel):
    synced: int


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(
    req: SyncPushRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    synced = 0
    for entry in req.entries:
        existing = await db.execute(
            select(FoodLog).where(FoodLog.id == uuid.UUID(entry.id))
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
        else:
            log = FoodLog(
                id=uuid.UUID(entry.id),
                user_id=uuid.UUID(user_id),
                product_id=entry.product_id,
                product_name=entry.product_name,
                meal_type=entry.meal_type,
                meal_date=entry.meal_date,
                grams=entry.grams,
                protein=entry.protein,
                fat=entry.fat,
                carbs=entry.carbs,
                calories=entry.calories,
            )
            db.add(log)
        synced += 1

    await db.commit()
    return SyncPushResponse(synced=synced)


@router.get("/pull")
async def sync_pull(
    since: datetime | None = Query(None),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    query = select(FoodLog).where(FoodLog.user_id == uuid.UUID(user_id))
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
        created_at=log.created_at,
        updated_at=log.updated_at,
    ) for log in logs]
