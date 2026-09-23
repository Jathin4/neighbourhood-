"""Provider directory (requirements doc section 19). A user opts into being a
service provider by registering a ProviderProfile for themselves; bookings
(see modules.bookings) are matched to providers by category."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.deps import current_user
from app.errors import not_found
from models.user import User
from schemas.marketplace import ProviderProfileIn, ProviderProfileOut
from services import marketplace as service

router = APIRouter(prefix="/marketplace", tags=["marketplace"])


@router.get("/providers/me", response_model=ProviderProfileOut)
async def get_my_provider(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await service.get_my_provider_profile(db, user.id)
    if profile is None:
        raise not_found("Provider profile")
    return profile


@router.put("/providers/me", response_model=ProviderProfileOut)
async def upsert_my_provider(
    body: ProviderProfileIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.upsert_my_provider_profile(db, user.id, body.business_name, body.category)


@router.get("/providers", response_model=list[ProviderProfileOut])
async def list_providers(
    category: str | None = Query(default=None),
    _: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_providers(db, category)
