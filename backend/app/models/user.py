import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, Float, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    name: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    daily_calorie_goal: Mapped[Optional[float]] = mapped_column(Float, default=2000)
    daily_protein_goal: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    daily_fat_goal: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    daily_carbs_goal: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
