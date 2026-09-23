import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.marketplace import ProviderProfile


async def get_my_provider_profile(db: AsyncSession, user_id: uuid.UUID) -> ProviderProfile | None:
    return await db.scalar(select(ProviderProfile).where(ProviderProfile.user_id == user_id))


async def upsert_my_provider_profile(
    db: AsyncSession, user_id: uuid.UUID, business_name: str, category: str
) -> ProviderProfile:
    profile = await get_my_provider_profile(db, user_id)
    if profile is None:
        profile = ProviderProfile(user_id=user_id, business_name=business_name, category=category)
        db.add(profile)
    else:
        profile.business_name = business_name
        profile.category = category
    await db.flush()
    return profile


async def list_providers(db: AsyncSession, category: str | None) -> list[ProviderProfile]:
    q = select(ProviderProfile)
    if category:
        q = q.where(ProviderProfile.category == category)
    return list(await db.scalars(q.order_by(ProviderProfile.business_name)))
