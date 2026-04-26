import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from pydantic import BaseModel, EmailStr
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models.food_log import FoodLog
from app.models.user import User
from app.routers.deps import get_current_user_id
from app.services.auth import get_password_hash, verify_password, create_access_token

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/auth", tags=["auth"])


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    id_token: str
    name: Optional[str] = None
    email: Optional[str] = None
    photo_url: Optional[str] = None


class AppleAuthRequest(BaseModel):
    identity_token: str
    authorization_code: Optional[str] = None
    user_identifier: Optional[str] = None
    name: Optional[str] = None
    email: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    name: Optional[str] = None


@router.post("/register", response_model=TokenResponse)
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = User(
        email=req.email,
        hashed_password=get_password_hash(req.password),
        name=req.name,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        user_id=str(user.id),
        email=user.email,
        name=user.name,
    )


@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        user_id=str(user.id),
        email=user.email,
        name=user.name,
    )


@router.post("/google", response_model=TokenResponse)
async def google_auth(req: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    email = req.email
    name = req.name

    if req.id_token and settings.google_client_id:
        try:
            idinfo = google_id_token.verify_oauth2_token(
                req.id_token,
                google_requests.Request(),
                settings.google_client_id,
            )
            email = idinfo.get("email", email)
            name = idinfo.get("name", name)
        except ValueError:
            logger.warning("Invalid Google ID token, falling back to client data")

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is required",
        )

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=email,
            hashed_password=get_password_hash("google-oauth-no-password"),
            name=name,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
    elif name and not user.name:
        user.name = name
        await db.commit()

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        user_id=str(user.id),
        email=user.email,
        name=user.name,
    )


def _fallback_apple_email(user_identifier: str) -> str:
    safe_id = "".join(ch for ch in user_identifier if ch.isalnum())[:64]
    return f"apple-{safe_id or 'user'}@privaterelay.appleid.com"


@router.post("/apple", response_model=TokenResponse)
async def apple_auth(req: AppleAuthRequest, db: AsyncSession = Depends(get_db)):
    email = req.email
    if not email and req.user_identifier:
        email = _fallback_apple_email(req.user_identifier)
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apple user identifier is required",
        )

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=email,
            hashed_password=get_password_hash("apple-oauth-no-password"),
            name=req.name,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
    elif req.name and not user.name:
        user.name = req.name
        await db.commit()

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        user_id=str(user.id),
        email=user.email,
        name=user.name,
    )


@router.delete("/me")
async def delete_current_account(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(delete(FoodLog).where(FoodLog.user_id == user_id))

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is not None:
        await db.delete(user)

    await db.commit()
    return {"deleted": True}
