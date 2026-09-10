import uuid

from sqlalchemy import JSON, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base
from app.models.base import PkMixin, TimestampMixin


class AuditLog(PkMixin, TimestampMixin, Base):
    """Append-only record of sensitive admin / financial / permission actions (§1, §13)."""

    __tablename__ = "audit_logs"

    actor_id: Mapped[uuid.UUID | None] = mapped_column(index=True)
    action: Mapped[str] = mapped_column(String(80), index=True)
    entity: Mapped[str] = mapped_column(String(60))
    entity_id: Mapped[str | None] = mapped_column(String(60))
    correlation_id: Mapped[str | None] = mapped_column(String(60))
    meta: Mapped[dict] = mapped_column(JSON, default=dict)
