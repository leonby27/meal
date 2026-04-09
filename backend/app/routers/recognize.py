from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel

from app.routers.deps import get_current_user_id
from app.services.timeweb_ai import recognize_food

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
    ingredients: list[Ingredient]
    per_100g: NutritionInfo
    total: NutritionInfo


@router.post("/recognize", response_model=RecognitionResponse)
async def recognize(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    image_bytes = await file.read()
    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 10MB)")

    try:
        result = recognize_food(image_bytes)
        if hasattr(result, "__await__"):
            result = await result
        return RecognitionResponse(**result)
    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail=f"AI recognition failed: {str(e)}",
        )
