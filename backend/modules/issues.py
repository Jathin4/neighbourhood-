"""Resident-raised issues/complaints, resolved by a Community Admin or a
Committee Member holding community.issue.manage (requirements doc §7)."""
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.deps import current_user
from models.user import User
from schemas.issues import IssueActionIn, IssueIn, IssueOut
from services import issues as service

router = APIRouter(prefix="/issues", tags=["issues"])


@router.post("", response_model=IssueOut, status_code=201)
async def create_issue(
    body: IssueIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    issue = await service.create_issue(db, user, body.community_id, body.category, body.title)
    return await service.serialize_one(db, issue)


@router.get("/mine", response_model=list[IssueOut])
async def list_mine(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    issues = await service.list_my_issues(db, user.id)
    return await service.serialize_many(db, issues)


@router.get("", response_model=list[IssueOut])
async def list_for_community(
    community_id: uuid.UUID = Query(...),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    issues = await service.list_community_issues(db, user, community_id)
    return await service.serialize_many(db, issues)


@router.patch("/{id}", response_model=IssueOut)
async def act_on_issue(
    id: uuid.UUID,
    body: IssueActionIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
):
    issue = await service.act_on_issue(db, user, id, body.action)
    return await service.serialize_one(db, issue)
