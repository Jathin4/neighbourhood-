import uuid

from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app import audit, rbac
from app.db import get_db
from app.deps import current_user, get_membership, require
from app.enums import MembershipStatus, PlatformRole
from app.errors import forbidden
from models.community import Community
from models.user import User
from schemas.community import (
    CommunityIn,
    CommunityOut,
    CommunityUpdateIn,
    EventIn,
    EventOut,
    ImportSummary,
    JoinRequestIn,
    MembershipOut,
    MembershipUpdateIn,
    NoticeIn,
    NoticeOut,
    UnitBulkIn,
    UnitOut,
)
from services import community as service

router = APIRouter(prefix="/communities", tags=["communities"])


async def require_member_or_platform(
    id: uuid.UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    if user.platform_role in (PlatformRole.platform_ops, PlatformRole.super_admin):
        return user
    m = await get_membership(db, user.id, id)
    if m is not None and m.status == MembershipStatus.active:
        return user
    raise forbidden("Not a member of this community")


async def require_member_or_platform_cid(
    community_id: uuid.UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    if user.platform_role in (PlatformRole.platform_ops, PlatformRole.super_admin):
        return user
    m = await get_membership(db, user.id, community_id)
    if m is not None and m.status == MembershipStatus.active:
        return user
    raise forbidden("Not a member of this community")


@router.post("", response_model=CommunityOut, status_code=201)
async def create_community(
    body: CommunityIn,
    user: User = Depends(require(rbac.CAP_COMMUNITY_CREATE)),
    db: AsyncSession = Depends(get_db),
):
    community = await service.create_community(db, body.model_dump())
    await audit.record(
        db, actor_id=user.id, action="community.create", entity="community", entity_id=community.id
    )
    return community


@router.get("", response_model=list[CommunityOut])
async def list_communities(
    search: str | None = Query(default=None),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    if user.platform_role in (PlatformRole.platform_ops, PlatformRole.super_admin):
        q = select(Community)
        if search:
            q = q.where(Community.name.ilike(f"%{search}%"))
        return list(await db.scalars(q.order_by(Community.name)))
    # Residents see only communities they belong to.
    from models.membership import Membership

    q = (
        select(Community)
        .join(Membership, Membership.community_id == Community.id)
        .where(Membership.user_id == user.id)
    )
    if search:
        q = q.where(Community.name.ilike(f"%{search}%"))
    return list(await db.scalars(q.order_by(Community.name)))


@router.get("/{id}", response_model=CommunityOut)
async def get_community(
    id: uuid.UUID,
    _: User = Depends(require_member_or_platform),
    db: AsyncSession = Depends(get_db),
):
    return await service.get_community(db, id)


@router.patch("/{id}", response_model=CommunityOut)
async def update_community(
    id: uuid.UUID,
    body: CommunityUpdateIn,
    user: User = Depends(require(rbac.CAP_COMMUNITY_UPDATE)),
    db: AsyncSession = Depends(get_db),
):
    community = await service.update_community(db, id, body.model_dump(exclude_unset=True))
    await audit.record(
        db, actor_id=user.id, action="community.update", entity="community", entity_id=id
    )
    return community


@router.get("/{id}/units", response_model=list[UnitOut])
async def list_units(
    id: uuid.UUID,
    _: User = Depends(require_member_or_platform),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_units(db, id)


@router.post("/{community_id}/units", response_model=list[UnitOut], status_code=201)
async def add_units(
    community_id: uuid.UUID,
    body: UnitBulkIn,
    _: User = Depends(require(rbac.CAP_UNIT_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    return await service.add_units(
        db, community_id, [u.model_dump() for u in body.units]
    )


@router.post("/{community_id}/members", response_model=MembershipOut, status_code=201)
async def request_membership(
    community_id: uuid.UUID,
    body: JoinRequestIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    return await service.request_membership(
        db, community_id, user.id, body.unit_id, body.household_relationship
    )


@router.get("/{community_id}/members", response_model=list[MembershipOut])
async def list_members(
    community_id: uuid.UUID,
    status: str | None = Query(default=None),
    _: User = Depends(require(rbac.CAP_MEMBER_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_memberships(db, community_id, status)


@router.patch(
    "/{community_id}/members/{membership_id}", response_model=MembershipOut
)
async def update_member(
    community_id: uuid.UUID,
    membership_id: uuid.UUID,
    body: MembershipUpdateIn,
    user: User = Depends(require(rbac.CAP_MEMBER_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    changes = body.model_dump(exclude_unset=True)
    changes = {k: (v.value if hasattr(v, "value") else v) for k, v in changes.items()}
    membership = await service.update_membership(db, community_id, membership_id, changes)
    await audit.record(
        db,
        actor_id=user.id,
        action="community.member.update",
        entity="membership",
        entity_id=membership_id,
        meta=changes,
    )
    return membership


@router.post("/{community_id}/members/import", response_model=ImportSummary)
async def import_residents(
    community_id: uuid.UUID,
    file: UploadFile = File(...),
    user: User = Depends(require(rbac.CAP_RESIDENT_IMPORT)),
    db: AsyncSession = Depends(get_db),
):
    summary = await service.import_residents_csv(db, community_id, await file.read())
    await audit.record(
        db,
        actor_id=user.id,
        action="community.resident.import",
        entity="community",
        entity_id=community_id,
        meta={"created": summary.created, "existing": summary.existing, "errors": summary.errors},
    )
    return summary


@router.post("/{community_id}/notices", response_model=NoticeOut, status_code=201)
async def create_notice(
    community_id: uuid.UUID,
    body: NoticeIn,
    user: User = Depends(require(rbac.CAP_NOTICE_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    notice = await service.create_notice(db, community_id, user.id, body.model_dump())
    return {**body.model_dump(), "id": notice.id, "created_at": notice.created_at, "read": True}


@router.get("/{community_id}/notices", response_model=list[NoticeOut])
async def list_notices(
    community_id: uuid.UUID,
    user: User = Depends(require_member_or_platform_cid),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_notices(db, community_id, user.id)


@router.post("/{community_id}/notices/{notice_id}/read", status_code=204)
async def mark_notice_read(
    community_id: uuid.UUID,
    notice_id: uuid.UUID,
    user: User = Depends(require_member_or_platform_cid),
    db: AsyncSession = Depends(get_db),
):
    await service.mark_notice_read(db, notice_id, user.id)


@router.post("/{community_id}/events", response_model=EventOut, status_code=201)
async def create_event(
    community_id: uuid.UUID,
    body: EventIn,
    user: User = Depends(require(rbac.CAP_EVENT_MANAGE)),
    db: AsyncSession = Depends(get_db),
):
    event = await service.create_event(db, community_id, user.id, body.model_dump())
    return {**body.model_dump(), "id": event.id, "rsvp_count": 0, "rsvped": False}


@router.get("/{community_id}/events", response_model=list[EventOut])
async def list_events(
    community_id: uuid.UUID,
    user: User = Depends(require_member_or_platform_cid),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_events(db, community_id, user.id)


@router.post("/{community_id}/events/{event_id}/rsvp")
async def toggle_rsvp(
    community_id: uuid.UUID,
    event_id: uuid.UUID,
    user: User = Depends(require_member_or_platform_cid),
    db: AsyncSession = Depends(get_db),
):
    rsvped = await service.toggle_rsvp(db, event_id, user.id)
    return {"rsvped": rsvped}
