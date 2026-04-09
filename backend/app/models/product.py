from datetime import datetime
from typing import Optional

from sqlalchemy import String, Float, Text, DateTime, func, Integer, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(500), index=True)
    weight_grams: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    protein_per_100g: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    fat_per_100g: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    carbs_per_100g: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    calories_per_100g: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    image_url: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    brand: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    country: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    category: Mapped[Optional[str]] = mapped_column(String(300), index=True, nullable=True)
    composition: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    price: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    is_user_created: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
