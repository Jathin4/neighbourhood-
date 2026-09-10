import uuid

from sqlalchemy import JSON, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base
from app.enums import CommunityRole, MembershipStatus, VerificationStatus
from app.models.base import PkMixin, TimestampMixin


class Household(PkMixin, TimestampMixin, Base):
    __tablename__ = "households"

    community_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("communities.id", ondelete="CASCADE"), index=True
    )
    unit_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("units.id", ondelete="SET NULL"))
    name: Mapped[str | None] = mapped_column(String(120))
    status: Mapped[str] = mapped_column(String(20), default="active")


class Membership(PkMixin, TimestampMixin, Base):
    __tablename__ = "memberships"
    __table_args__ = (UniqueConstraint("user_id", "community_id"),)

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    community_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("communities.id", ondelete="CASCADE"), index=True
    )
    household_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("households.id", ondelete="SET NULL")
    )
    unit_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("units.id", ondelete="SET NULL"))

    role: Mapped[str] = mapped_column(String(20), default=CommunityRole.resident)
    status: Mapped[str] = mapped_column(String(20), default=MembershipStatus.pending)
    verification_status: Mapped[str] = mapped_column(
        String(20), default=VerificationStatus.unverified
    )
    household_relationship: Mapped[str | None] = mapped_column(String(40))
    # Extra capabilities granted to a committee_member beyond their role defaults (§1).
    capabilities: Mapped[list] = mapped_column(JSON, default=list)
