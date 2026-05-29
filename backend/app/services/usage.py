from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.recognition_usage import RecognitionUsage


async def reserve_recognition(db: AsyncSession, user_id: str, limit: int) -> bool:
    """Count one recognition against the user's daily cap.

    Returns True if the call is allowed (and records it), False if the user has
    already hit `limit` recognitions today (UTC). A non-positive `limit`
    disables the cap. The increment happens here, before the AI call, because
    each dispatched request is what costs tokens — we cap attempts, not
    successes. Read-modify-write is fine for a cost guard: a rare concurrent
    overshoot of a request or two is harmless.
    """
    if limit <= 0:
        return True

    today = datetime.now(timezone.utc).date()
    result = await db.execute(
        select(RecognitionUsage)
        .where(RecognitionUsage.user_id == user_id)
        .where(RecognitionUsage.day == today)
    )
    usage = result.scalar_one_or_none()

    if usage is None:
        db.add(RecognitionUsage(user_id=user_id, day=today, count=1))
        await db.commit()
        return True

    if usage.count >= limit:
        return False

    usage.count += 1
    await db.commit()
    return True
