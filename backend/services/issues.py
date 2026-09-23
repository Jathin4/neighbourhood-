import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app import rbac
from app.enums import IssueStatus, MembershipStatus, PlatformRole
from app.errors import AppError, forbidden, not_found
from models.community_content import Issue
from models.membership import Membership
from models.user import User


async def _active_membership(db: AsyncSession, user_id: uuid.UUID, community_id: uuid.UUID) -> Membership | None:
    return await db.scalar(
        select(Membership).where(
            Membership.user_id == user_id,
            Membership.community_id == community_id,
            Membership.status == MembershipStatus.active,
        )
    )


async def _can_manage(db: AsyncSession, user: User, community_id: uuid.UUID) -> bool:
    if rbac.platform_can(user.platform_role, rbac.CAP_ISSUE_MANAGE):
        return True
    m = await _active_membership(db, user.id, community_id)
    return m is not None and rbac.community_can(m.role, m.capabilities, rbac.CAP_ISSUE_MANAGE)


async def create_issue(
    db: AsyncSession, user: User, community_id: uuid.UUID, category: str, title: str
) -> Issue:
    if user.platform_role not in (PlatformRole.platform_ops, PlatformRole.super_admin):
        member = await _active_membership(db, user.id, community_id)
        if member is None:
            raise forbidden("Not an active member of this community")
    issue = Issue(
        community_id=community_id,
        raised_by=user.id,
        category=category,
        title=title,
        status=IssueStatus.submitted,
    )
    db.add(issue)
    await db.flush()
    return issue


async def list_my_issues(db: AsyncSession, user_id: uuid.UUID) -> list[Issue]:
    return list(
        await db.scalars(
            select(Issue).where(Issue.raised_by == user_id).order_by(Issue.created_at.desc())
        )
    )


async def list_community_issues(db: AsyncSession, user: User, community_id: uuid.UUID) -> list[Issue]:
    if not await _can_manage(db, user, community_id):
        raise forbidden(f"Missing capability: {rbac.CAP_ISSUE_MANAGE}")
    return list(
        await db.scalars(
            select(Issue)
            .where(Issue.community_id == community_id)
            .order_by(Issue.created_at.desc())
        )
    )


async def act_on_issue(db: AsyncSession, user: User, issue_id: uuid.UUID, action: str) -> Issue:
    issue = await db.get(Issue, issue_id)
    if issue is None:
        raise not_found("Issue")

    if action == "reopen":
        if issue.raised_by != user.id:
            raise forbidden("Only the resident who raised it can reopen it")
        if issue.status != IssueStatus.resolved:
            raise AppError("invalid_state", "Only a resolved issue can be reopened", 400)
        issue.status = IssueStatus.reopened
    else:
        if not await _can_manage(db, user, issue.community_id):
            raise forbidden(f"Missing capability: {rbac.CAP_ISSUE_MANAGE}")
        issue.status = IssueStatus.in_progress if action == "start" else IssueStatus.resolved

    await db.flush()
    return issue


async def _names(db: AsyncSession, ids: set[uuid.UUID]) -> dict[uuid.UUID, tuple[str | None, str]]:
    ids.discard(None)
    if not ids:
        return {}
    rows = await db.execute(select(User.id, User.name, User.mobile).where(User.id.in_(ids)))
    return {r.id: (r.name, r.mobile) for r in rows}


async def serialize_many(db: AsyncSession, issues: list[Issue]) -> list[dict]:
    names = await _names(db, {i.raised_by for i in issues})
    out = []
    for i in issues:
        name, mobile = names.get(i.raised_by, (None, ''))
        out.append({
            "id": i.id,
            "community_id": i.community_id,
            "raised_by": i.raised_by,
            "raised_by_name": name or mobile or 'Unknown',
            "category": i.category,
            "title": i.title,
            "status": i.status,
            "created_at": i.created_at,
        })
    return out


async def serialize_one(db: AsyncSession, issue: Issue) -> dict:
    return (await serialize_many(db, [issue]))[0]
