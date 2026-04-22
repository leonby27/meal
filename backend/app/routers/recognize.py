import logging
from typing import List

from fastapi import APIRouter, Depends, Form, HTTPException, UploadFile, File
from pydantic import BaseModel

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


class RecognitionResponse(BaseModel):
    name: str
    total_grams: float
    ingredients: List[Ingredient]
    per_100g: NutritionInfo
    total: NutritionInfo


class TextRecognitionRequest(BaseModel):
    text: str


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


@router.post("/recognize", response_model=RecognitionResponse)
async def recognize(
    file: UploadFile = File(...),
    text: str = Form(default=""),
    user_id: str = Depends(get_current_user_id),
):
    image_bytes = await file.read()
    user_text = text.strip() if text else ""
    logger.info(
        "recognize: filename=%s content_type=%s size=%d text=%r bytes_head=%s",
        file.filename, file.content_type, len(image_bytes),
        user_text[:100] if user_text else "",
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
        result = await recognize_food(image_bytes, text=user_text or None)
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
):
    text = request.text.strip()
    if not text:
        raise HTTPException(status_code=400, detail="Text is empty")

    if len(text) > 2000:
        raise HTTPException(status_code=400, detail="Text too long (max 2000 chars)")

    logger.info("recognize_text: user=%s text=%r", user_id, text[:100])

    try:
        result = await recognize_food_from_text(text)
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
