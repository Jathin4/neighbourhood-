import uuid

from sqlalchemy import JSON, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base
from app.enums import AccountStatus
from app.models.base import PkMixin, TimestampMixin


class Community(PkMixin, TimestampMixin, Base):
    __tablename__ = "communities"

    name: Mapped[str] = mapped_column(String(160), index=True)
    address: Mapped[str | None] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(20), default=AccountStatus.active)
    # Feature flags / limits / SLAs / fees — nothing hard-coded (guardrail §23).
    settings: Mapped[dict] = mapped_column(JSON, default=dict)


class Unit(PkMixin, TimestampMixin, Base):
    __tablename__ = "units"
    __table_args__ = (UniqueConstraint("community_id", "tower", "unit_number"),)

    community_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("communities.id", ondelete="CASCADE"), index=True
    )
    tower: Mapped[str] = mapped_column(String(40))
    unit_number: Mapped[str] = mapped_column(String(40))
