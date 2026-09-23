import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.enums import CommunityRole, MembershipStatus
from app.errors import not_found
from app.models.audit import AuditLog
from app.models.community import Community
from app.models.marketplace import Booking, ProviderProfile
from app.models.membership import Membership
from app.models.user import User

DEFAULT_LIMIT = 50
MAX_LIMIT = 200


def _clamp(limit: int) -> int:
    return max(1, min(limit, MAX_LIMIT))


async def list_users(
    db: AsyncSession,
    *,
    search: str | None,
    status: str | None,
    limit: int = DEFAULT_LIMIT,
    offset: int = 0,
) -> list[User]:
    q = select(User)
    if search:
        like = f"%{search}%"
        q = q.where(or_(User.mobile.ilike(like), User.name.ilike(like)))
    if status:
        q = q.where(User.status == status)
    q = q.order_by(User.created_at.desc()).limit(_clamp(limit)).offset(max(0, offset))
    return list(await db.scalars(q))


async def update_user_status(db: AsyncSession, user_id: uuid.UUID, status: str) -> User:
    user = await db.get(User, user_id)
    if user is None:
        raise not_found("User")
    user.status = status
    await db.flush()
    return user


async def list_audit_logs(
    db: AsyncSession, *, limit: int = DEFAULT_LIMIT, offset: int = 0
) -> list[tuple[AuditLog, str | None]]:
    """Returns (log, actor_mobile) pairs — actor_mobile is None for system/anonymous actions."""
    q = (
        select(AuditLog, User.mobile)
        .join(User, User.id == AuditLog.actor_id, isouter=True)
        .order_by(AuditLog.created_at.desc())
        .limit(_clamp(limit))
        .offset(max(0, offset))
    )
    result = await db.execute(q)
    return [(row[0], row[1]) for row in result.all()]


async def _count(db: AsyncSession, *where) -> int:
    return await db.scalar(select(func.count()).select_from(Membership).where(*where)) or 0


async def get_dashboard_stats(db: AsyncSession) -> dict:
    total_communities = await db.scalar(select(func.count()).select_from(Community)) or 0
    total_bookings = await db.scalar(select(func.count()).select_from(Booking)) or 0
    service_providers = await db.scalar(select(func.count()).select_from(ProviderProfile)) or 0
    total_residents = await _count(
        db, Membership.role == CommunityRole.resident, Membership.status == MembershipStatus.active
    )
    community_admins = await _count(
        db,
        Membership.role == CommunityRole.community_admin,
        Membership.status == MembershipStatus.active,
    )
    committee_members = await _count(
        db,
        Membership.role == CommunityRole.committee_member,
        Membership.status == MembershipStatus.active,
    )
    pending = await _count(db, Membership.status == MembershipStatus.pending)
    return {
        "total_communities": total_communities,
        "total_residents": total_residents,
        "community_admins": community_admins,
        "committee_members": committee_members,
        "service_providers": service_providers,
        "total_bookings": total_bookings,
        "pending_membership_approvals": pending,
    }


async def get_growth_series(db: AsyncSession, days: int = 10) -> dict:
    """New users and new bookings per day for the last ``days`` days
    (including today) — real counts, not a fabricated trend line."""
    today = datetime.now(UTC).date()
    start = today - timedelta(days=days - 1)
    start_dt = datetime.combine(start, datetime.min.time(), tzinfo=UTC)

    user_rows = dict(
        (
            await db.execute(
                select(func.date(User.created_at), func.count())
                .where(User.created_at >= start_dt)
                .group_by(func.date(User.created_at))
            )
        ).all()
    )
    booking_rows = dict(
        (
            await db.execute(
                select(func.date(Booking.created_at), func.count())
                .where(Booking.created_at >= start_dt)
                .group_by(func.date(Booking.created_at))
            )
        ).all()
    )

    labels: list[str] = []
    new_users: list[int] = []
    new_bookings: list[int] = []
    for i in range(days):
        day = start + timedelta(days=i)
        key = day.isoformat()
        labels.append(f"{day.strftime('%b')} {day.day}")
        new_users.append(int(user_rows.get(key) or user_rows.get(day) or 0))
        new_bookings.append(int(booking_rows.get(key) or booking_rows.get(day) or 0))

    return {"labels": labels, "new_users": new_users, "new_bookings": new_bookings}
