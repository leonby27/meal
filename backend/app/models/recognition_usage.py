from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class RecognitionUsage(Base):
    """Per-user, per-day count of AI recognition requests.

    Backs the `max_recognitions_per_day` cap (see config + recognize router).
    One row per (user, UTC day); `count` is the number of recognition attempts
    dispatched to the AI agent that day — attempts, not successes, since each
    dispatch is what costs tokens.
    """

    __tablename__ = "recognition_usage"

    user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
