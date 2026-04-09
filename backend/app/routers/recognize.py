import logging
from typing import List

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel

from app.routers.deps import get_current_user_id
from app.services.timeweb_ai import recognize_food

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


IMAGE_SIGNATURES = [
    (b'\xff\xd8\xff', 'image/jpeg'),
    (b'\x89PNG', 'image/png'),
    (b'GIF8', 'image/gif'),
    (b'RIFF', 'image/webp'),
]


def detect_image_type(data: bytes) -> str:
    for sig, mime in IMAGE_SIGNATURES:
        if data[:len(sig)] == sig:
            return mime
    return ''


@router.post("/recognize", response_model=RecognitionResponse)
async def recognize(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
):
    image_bytes = await file.read()
    logger.info(
        "recognize: filename=%s content_type=%s size=%d bytes_head=%s",
        file.filename, file.content_type, len(image_bytes), image_bytes[:8].hex() if image_bytes else "empty",
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
        result = await recognize_food(image_bytes)
        return RecognitionResponse(**result)
    except Exception as e:
        logger.exception("AI recognition failed")
        raise HTTPException(
            status_code=502,
            detail=f"AI recognition failed: {str(e)}",
        )
