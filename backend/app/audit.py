import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.errors import correlation_id
from models.audit import AuditLog


async def record(
    db: AsyncSession,
    *,
    actor_id: uuid.UUID | None,
    action: str,
    entity: str,
    entity_id: str | uuid.UUID | None = None,
    meta: dict | None = None,
) -> None:
    db.add(
        AuditLog(
            actor_id=actor_id,
            action=action,
            entity=entity,
            entity_id=str(entity_id) if entity_id is not None else None,
            correlation_id=correlation_id.get(),
            meta=meta or {},
        )
    )
    await db.flush()
