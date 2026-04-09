import enum
import uuid
from datetime import datetime, date
from typing import Optional

from sqlalchemy import String, Float, DateTime, Date, Enum, ForeignKey, func, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class MealType(str, enum.Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"


class FoodLog(Base):
    __tablename__ = "food_logs"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id"), index=True
    )
    product_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    product_name: Mapped[str] = mapped_column(String(500))
    meal_type: Mapped[MealType] = mapped_column(Enum(MealType))
    meal_date: Mapped[date] = mapped_column(Date, index=True)
    grams: Mapped[float] = mapped_column(Float)
    protein: Mapped[float] = mapped_column(Float, default=0)
    fat: Mapped[float] = mapped_column(Float, default=0)
    carbs: Mapped[float] = mapped_column(Float, default=0)
    calories: Mapped[float] = mapped_column(Float, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
