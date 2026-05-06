from typing import Dict

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user_setting import UserSetting
from app.routers.deps import get_current_user_id

router = APIRouter(prefix="/api/users", tags=["users"])


class SettingsRequest(BaseModel):
    settings: Dict[str, str]


class SettingsResponse(BaseModel):
    settings: Dict[str, str]


@router.get("/me/settings", response_model=SettingsResponse)
async def get_settings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserSetting).where(UserSetting.user_id == user_id)
    )
    rows = result.scalars().all()
    return SettingsResponse(settings={row.key: row.value for row in rows})


@router.post("/me/settings", response_model=SettingsResponse)
async def post_settings(
    req: SettingsRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    # Read existing rows in one go, then upsert in-memory. This is dialect-
    # agnostic and runs only on login, so the few extra queries are fine.
    if req.settings:
        result = await db.execute(
            select(UserSetting).where(UserSetting.user_id == user_id)
        )
        existing = {row.key: row for row in result.scalars().all()}

        for key, value in req.settings.items():
            row = existing.get(key)
            if row is None:
                db.add(UserSetting(user_id=user_id, key=key, value=value))
            else:
                row.value = value

        await db.commit()

    result = await db.execute(
        select(UserSetting).where(UserSetting.user_id == user_id)
    )
    rows = result.scalars().all()
    return SettingsResponse(settings={row.key: row.value for row in rows})
