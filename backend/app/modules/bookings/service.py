import uuid

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.enums import BookingStatus
from app.errors import AppError, forbidden, not_found
from app.models.marketplace import Booking, ProviderProfile
from app.models.user import User
from app.modules.marketplace.service import get_my_provider_profile


async def create_booking(
    db: AsyncSession, resident_id: uuid.UUID, category: str, title: str, note: str | None
) -> Booking:
    booking = Booking(
        resident_user_id=resident_id,
        category=category,
        title=title,
        note=note,
        status=BookingStatus.requested,
    )
    db.add(booking)
    await db.flush()
    return booking


async def list_my_bookings(db: AsyncSession, user_id: uuid.UUID) -> list[Booking]:
    q = select(Booking).where(
        or_(Booking.resident_user_id == user_id, Booking.provider_user_id == user_id)
    )
    return list(await db.scalars(q.order_by(Booking.created_at.desc())))


async def list_leads(db: AsyncSession, user_id: uuid.UUID) -> list[Booking]:
    """Open, unclaimed requests matching the caller's provider category."""
    profile = await get_my_provider_profile(db, user_id)
    if profile is None:
        return []
    q = select(Booking).where(
        Booking.status == BookingStatus.requested,
        Booking.provider_user_id.is_(None),
        Booking.category == profile.category,
    )
    return list(await db.scalars(q.order_by(Booking.created_at)))


async def act_on_booking(
    db: AsyncSession, booking_id: uuid.UUID, user_id: uuid.UUID, action: str
) -> Booking:
    booking = await db.get(Booking, booking_id)
    if booking is None:
        raise not_found("Booking")

    if action == "accept":
        if booking.status != BookingStatus.requested or booking.provider_user_id is not None:
            raise AppError("already_claimed", "This lead was already claimed", 409)
        profile = await get_my_provider_profile(db, user_id)
        if profile is None or profile.category != booking.category:
            raise forbidden("Not a matching provider for this category")
        booking.provider_user_id = user_id
        booking.status = BookingStatus.accepted
    elif action == "complete":
        if booking.provider_user_id != user_id:
            raise forbidden("Not your booking")
        booking.status = BookingStatus.completed
    elif action == "cancel":
        if booking.resident_user_id != user_id:
            raise forbidden("Not your booking")
        if booking.status not in (BookingStatus.requested, BookingStatus.accepted):
            raise AppError("invalid_state", "Cannot cancel a completed booking", 400)
        booking.status = BookingStatus.cancelled

    await db.flush()
    return booking


async def _names(db: AsyncSession, ids: set[uuid.UUID]) -> dict[uuid.UUID, tuple[str | None, str]]:
    ids.discard(None)
    if not ids:
        return {}
    rows = await db.execute(select(User.id, User.name, User.mobile).where(User.id.in_(ids)))
    return {r.id: (r.name, r.mobile) for r in rows}


async def _business_names(db: AsyncSession, user_ids: set[uuid.UUID]) -> dict[uuid.UUID, str]:
    user_ids.discard(None)
    if not user_ids:
        return {}
    rows = await db.execute(
        select(ProviderProfile.user_id, ProviderProfile.business_name).where(
            ProviderProfile.user_id.in_(user_ids)
        )
    )
    return {r.user_id: r.business_name for r in rows}


def _to_out(
    booking: Booking,
    names: dict[uuid.UUID, tuple[str | None, str]],
    business_names: dict[uuid.UUID, str],
) -> dict:
    resident_name, resident_mobile = names.get(booking.resident_user_id, (None, ""))
    provider_name = (
        business_names.get(booking.provider_user_id) if booking.provider_user_id else None
    )
    return {
        "id": booking.id,
        "resident_user_id": booking.resident_user_id,
        "provider_user_id": booking.provider_user_id,
        "category": booking.category,
        "title": booking.title,
        "note": booking.note,
        "status": booking.status,
        "created_at": booking.created_at,
        "resident_name": resident_name or resident_mobile,
        "provider_name": provider_name,
    }


async def serialize_many(db: AsyncSession, bookings: list[Booking]) -> list[dict]:
    provider_ids = {b.provider_user_id for b in bookings if b.provider_user_id}
    ids = {b.resident_user_id for b in bookings} | provider_ids
    names = await _names(db, ids)
    business_names = await _business_names(db, set(provider_ids))
    return [_to_out(b, names, business_names) for b in bookings]


async def serialize_one(db: AsyncSession, booking: Booking) -> dict:
    return (await serialize_many(db, [booking]))[0]
