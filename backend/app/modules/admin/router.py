import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app import audit, rbac
from app.db import get_db
from app.deps import require
from app.models.user import User
from app.modules.admin import service
from app.modules.admin.schemas import (
    AuditLogOut,
    DashboardStatsOut,
    GrowthSeriesOut,
    UserAdminOut,
    UserStatusUpdateIn,
)

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users", response_model=list[UserAdminOut])
async def list_users(
    search: str | None = Query(default=None),
    status: str | None = Query(default=None),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    _: User = Depends(require(rbac.CAP_USER_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_users(db, search=search, status=status, limit=limit, offset=offset)


@router.patch("/users/{user_id}", response_model=UserAdminOut)
async def update_user_status(
    user_id: uuid.UUID,
    body: UserStatusUpdateIn,
    actor: User = Depends(require(rbac.CAP_USER_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    user = await service.update_user_status(db, user_id, body.status.value)
    await audit.record(
        db,
        actor_id=actor.id,
        action="user.status_update",
        entity="user",
        entity_id=user_id,
        meta={"status": body.status.value},
    )
    return user


@router.get("/audit-logs", response_model=list[AuditLogOut])
async def list_audit_logs(
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0, ge=0),
    _: User = Depends(require(rbac.CAP_AUDIT_VIEW)),
    db: AsyncSession = Depends(get_db),
):
    rows = await service.list_audit_logs(db, limit=limit, offset=offset)
    return [
        AuditLogOut(
            id=log.id,
            actor_id=log.actor_id,
            actor_mobile=mobile,
            action=log.action,
            entity=log.entity,
            entity_id=log.entity_id,
            correlation_id=log.correlation_id,
            meta=log.meta,
            created_at=log.created_at,
        )
        for log, mobile in rows
    ]


@router.get("/dashboard-stats", response_model=DashboardStatsOut)
async def dashboard_stats(
    _: User = Depends(require(rbac.CAP_USER_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_dashboard_stats(db)


@router.get("/growth-series", response_model=GrowthSeriesOut)
async def growth_series(
    days: int = Query(default=10, ge=2, le=90),
    _: User = Depends(require(rbac.CAP_USER_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_growth_series(db, days=days)
