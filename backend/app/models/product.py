from datetime import datetime

from sqlalchemy import String, Float, Text, DateTime, func, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(500), index=True)
    weight_grams: Mapped[float | None] = mapped_column(Float)
    protein_per_100g: Mapped[float | None] = mapped_column(Float)
    fat_per_100g: Mapped[float | None] = mapped_column(Float)
    carbs_per_100g: Mapped[float | None] = mapped_column(Float)
    calories_per_100g: Mapped[float | None] = mapped_column(Float)
    image_url: Mapped[str | None] = mapped_column(Text)
    brand: Mapped[str | None] = mapped_column(String(200))
    country: Mapped[str | None] = mapped_column(String(100))
    category: Mapped[str | None] = mapped_column(String(300), index=True)
    composition: Mapped[str | None] = mapped_column(Text)
    price: Mapped[float | None] = mapped_column(Float)
    is_user_created: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
