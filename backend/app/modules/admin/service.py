import uuid

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import not_found
from app.models.audit import AuditLog
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
