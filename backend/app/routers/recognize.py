import logging
from typing import List

from fastapi import APIRouter, Depends, Form, HTTPException, UploadFile, File
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user_setting import UserSetting
from app.routers.deps import get_current_user_id
from app.services.timeweb_ai import (
    AIRecognitionError,
    recognize_food,
    recognize_food_from_text,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["recognize"])


class NutritionInfo(BaseModel):
    protein: float
    fat: float
    carbs: float
    calories: float


class Ingredient(BaseModel):
    name: str
    grams: float
    protein: float = 0
    fat: float = 0
    carbs: float = 0
    calories: float = 0


class CompleteMacro(BaseModel):
    sugar_g: float | None = None
    fiber_g: float | None = None
    saturated_fat_g: float | None = None
    cholesterol_mg: float | None = None
    trans_fat_g: float | None = None
    sodium_mg: float | None = None
    glycemic_load: float | None = None
    caloric_density: float | None = None
    # NOVA classification 1–4
    processing_level: int | None = None


class GoalFit(BaseModel):
    positive: List[str] = []
    negative: List[str] = []


class RecognitionResponse(BaseModel):
    name: str
    total_grams: float
    ingredients: List[Ingredient]
    # Optional list of plausible extra ingredients the model thinks the
    # user might have added but that aren't visible / confirmed. Pure UI
    # hints — never folded into totals.
    suggestions: List[Ingredient] = []
    per_100g: NutritionInfo
    total: NutritionInfo
    health_rating: int | None = None
    health_comment: str | None = None
    # Short light-irony caption shown above the photo, in the user's locale.
    meal_quote: str | None = None
    # Detailed macro/quality breakdown — clients render worse/avg/good
    # statuses themselves from these numbers.
    complete_macro: CompleteMacro | None = None
    # Closed-list tag codes evaluating the dish against the user's goal.
    # Client localises the codes; see _TAG_CODES in timeweb_ai.py.
    goal_fit: GoalFit | None = None


class TextRecognitionRequest(BaseModel):
    text: str
    locale: str | None = None
    # Onboarding goal: 'lose' / 'maintain' / 'gain'. Optional — defaults to
    # balanced eating on the AI side.
    goal: str | None = None


IMAGE_SIGNATURES = [
    (b'\xff\xd8\xff', 'image/jpeg'),
    (b'\x89PNG', 'image/png'),
    (b'GIF8', 'image/gif'),
    (b'RIFF', 'image/webp'),
]


_KIND_TO_STATUS = {
    "rate_limited": 429,
    "upstream_5xx": 502,
    "upstream_4xx": 502,
    "network": 504,
    "truncated": 502,
    "parse_error": 502,
    "no_json": 502,
    "bad_response": 502,
}


def _status_for_kind(kind: str) -> int:
    return _KIND_TO_STATUS.get(kind, 502)


def detect_image_type(data: bytes) -> str:
    for sig, mime in IMAGE_SIGNATURES:
        if data[:len(sig)] == sig:
            return mime
    return ''


_ALLOWED_GOALS = {"lose", "maintain", "gain"}


def _normalize_goal(value: str | None) -> str | None:
    if not value:
        return None
    code = value.strip().lower()
    return code if code in _ALLOWED_GOALS else None


async def _goal_from_settings(user_id: str, db: AsyncSession) -> str | None:
    """Look up the persisted user_goal from user_settings. Returns None if
    the row is absent or the value is not one of the allowed codes."""
    result = await db.execute(
        select(UserSetting.value)
        .where(UserSetting.user_id == user_id)
        .where(UserSetting.key == "user_goal")
    )
    raw = result.scalar_one_or_none()
    return _normalize_goal(raw)


@router.post("/recognize", response_model=RecognitionResponse)
async def recognize(
    file: UploadFile = File(...),
    text: str = Form(default=""),
    locale: str = Form(default=""),
    goal: str = Form(default=""),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    image_bytes = await file.read()
    user_text = text.strip() if text else ""
    user_locale = locale.strip() or None
    user_goal = _normalize_goal(goal) or await _goal_from_settings(user_id, db)
    logger.info(
        "recognize: filename=%s content_type=%s size=%d text=%r locale=%s "
        "goal=%s bytes_head=%s",
        file.filename, file.content_type, len(image_bytes),
        user_text[:100] if user_text else "",
        user_locale,
        user_goal,
        image_bytes[:8].hex() if image_bytes else "empty",
    )

    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    detected = detect_image_type(image_bytes)
    if not detected:
        ct = file.content_type or ''
        if not ct.startswith('image/'):
            raise HTTPException(
                status_code=400,
                detail=f"File must be an image (got content_type={ct}, no image signature found)",
            )

    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")

    try:
        result = await recognize_food(
            image_bytes,
            text=user_text or None,
            locale=user_locale,
            goal=user_goal,
        )
        return RecognitionResponse(**result)
    except AIRecognitionError as e:
        logger.warning("AI recognition failed: kind=%s msg=%s", e.kind, e)
        status = _status_for_kind(e.kind)
        raise HTTPException(
            status_code=status,
            detail={"kind": e.kind, "message": str(e)},
        )
    except Exception as e:
        logger.exception("AI recognition crashed")
        raise HTTPException(
            status_code=502,
            detail={"kind": "unknown", "message": f"AI recognition failed: {e}"},
        )


@router.post("/recognize-text", response_model=RecognitionResponse)
async def recognize_text(
    request: TextRecognitionRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text is empty")

    if len(text) > 2000:
        raise HTTPException(status_code=400, detail="Text too long (max 2000 chars)")

    user_locale = (request.locale or "").strip() or None
    user_goal = (
        _normalize_goal(request.goal)
        or await _goal_from_settings(user_id, db)
    )
    logger.info(
        "recognize_text: user=%s locale=%s goal=%s text=%r",
        user_id, user_locale, user_goal, text[:100],
    )

    try:
        result = await recognize_food_from_text(
            text, locale=user_locale, goal=user_goal,
        )
        return RecognitionResponse(**result)
    except AIRecognitionError as e:
        logger.warning("AI text recognition failed: kind=%s msg=%s", e.kind, e)
        status = _status_for_kind(e.kind)
        raise HTTPException(
            status_code=status,
            detail={"kind": e.kind, "message": str(e)},
        )
    except Exception as e:
        logger.exception("AI text recognition crashed")
        raise HTTPException(
            status_code=502,
            detail={"kind": "unknown", "message": f"AI recognition failed: {e}"},
        )
