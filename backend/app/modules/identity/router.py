from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db import get_db
from app.deps import current_user
from app.models.user import User
from app.modules.identity import service
from app.modules.identity.schemas import (
    MyMembershipOut,
    OtpRequestIn,
    OtpRequestOut,
    OtpVerifyIn,
    RefreshIn,
    TokenPair,
    UserOut,
    UserUpdateIn,
)

settings = get_settings()

auth_router = APIRouter(prefix="/auth", tags=["auth"])
users_router = APIRouter(prefix="/users", tags=["users"])


def _pair(access: str, refresh: str) -> TokenPair:
    return TokenPair(
        access_token=access,
        refresh_token=refresh,
        expires_in=settings.access_token_ttl_minutes * 60,
    )


@auth_router.post("/otp/request", response_model=OtpRequestOut)
async def otp_request(body: OtpRequestIn, db: AsyncSession = Depends(get_db)):
    ttl, debug_code = await service.request_otp(db, body.mobile)
    return OtpRequestOut(expires_in=ttl, debug_code=debug_code)


@auth_router.post("/otp/verify", response_model=TokenPair)
async def otp_verify(body: OtpVerifyIn, db: AsyncSession = Depends(get_db)):
    _, access, refresh = await service.verify_otp(db, body.mobile, body.code)
    return _pair(access, refresh)


@auth_router.post("/dev-login", response_model=TokenPair)
async def dev_login(body: OtpRequestIn, db: AsyncSession = Depends(get_db)):
    """Dev-only shortcut: no OTP. Disabled unless ENV=dev."""
    _, access, refresh = await service.dev_login(db, body.mobile)
    return _pair(access, refresh)


@auth_router.post("/refresh", response_model=TokenPair)
async def refresh(body: RefreshIn, db: AsyncSession = Depends(get_db)):
    access, new_refresh = await service.rotate_refresh(db, body.refresh_token)
    return _pair(access, new_refresh)


@auth_router.post("/logout", status_code=204)
async def logout(body: RefreshIn, db: AsyncSession = Depends(get_db)):
    await service.logout(db, body.refresh_token)


@users_router.get("/me", response_model=UserOut)
async def get_me(user: User = Depends(current_user)):
    return user


@users_router.patch("/me", response_model=UserOut)
async def update_me(
    body: UserUpdateIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    data = body.model_dump(exclude_unset=True)
    if "email" in data and data["email"] is not None:
        data["email"] = str(data["email"])
    for field, value in data.items():
        setattr(user, field, value)
    await db.flush()
    return user


@users_router.get("/me/memberships", response_model=list[MyMembershipOut])
async def get_my_memberships(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_my_memberships(db, user.id)
