import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.enums import AccountStatus


class UserAdminOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    mobile: str
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
