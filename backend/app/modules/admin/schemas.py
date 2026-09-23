import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.enums import AccountStatus


class UserAdminOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    mobile: str | None
    name: str | None
    email: str | None
    status: str
    platform_role: str | None
    created_at: datetime


class UserStatusUpdateIn(BaseModel):
    status: AccountStatus


class AuditLogOut(BaseModel):
    id: uuid.UUID
    actor_id: uuid.UUID | None
    actor_mobile: str | None
    action: str
    entity: str
    entity_id: str | None
    correlation_id: str | None
    meta: dict
    created_at: datetime


class DashboardStatsOut(BaseModel):
    total_communities: int
    total_residents: int
    community_admins: int
    committee_members: int
    service_providers: int
    total_bookings: int
    pending_membership_approvals: int


class GrowthSeriesOut(BaseModel):
    labels: list[str]
    new_users: list[int]
    new_bookings: list[int]
