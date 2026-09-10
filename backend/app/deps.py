import uuid

import jwt
from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app import rbac
from app.db import get_db
from app.enums import MembershipStatus
from app.errors import AppError, forbidden
from app.models.membership import Membership
from app.models.user import User
from app.security import decode_access_token

bearer = HTTPBearer(auto_error=False)


async def current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    if creds is None:
        raise AppError("unauthenticated", "Missing bearer token", 401)
    try:
        user_id = decode_access_token(creds.credentials)
    except jwt.PyJWTError:
        raise AppError("unauthenticated", "Invalid or expired token", 401) from None
    user = await db.get(User, user_id)
    if user is None:
        raise AppError("unauthenticated", "Unknown user", 401)
    return user


async def get_membership(
    db: AsyncSession, user_id: uuid.UUID, community_id: uuid.UUID
) -> Membership | None:
    return await db.scalar(
        select(Membership).where(
            Membership.user_id == user_id, Membership.community_id == community_id
        )
    )


def _community_id_from_path(request: Request) -> uuid.UUID | None:
    raw = request.path_params.get("community_id") or request.path_params.get("id")
    if raw is None:
        return None
    try:
        return uuid.UUID(str(raw))
    except ValueError:
        return None


def require(capability: str):
    """Dependency: allow the request only if the caller holds ``capability``.

    Checks platform role first, then the caller's active membership in the
    community named by ``{community_id}`` / ``{id}`` in the path.
    """

    async def _dep(
        request: Request,
        user: User = Depends(current_user),
        db: AsyncSession = Depends(get_db),
    ) -> User:
        if rbac.platform_can(user.platform_role, capability):
            return user
        community_id = _community_id_from_path(request)
        if community_id is not None:
            m = await get_membership(db, user.id, community_id)
            if (
                m is not None
                and m.status == MembershipStatus.active
                and rbac.community_can(m.role, m.capabilities, capability)
            ):
                return user
        raise forbidden(f"Missing capability: {capability}")

    return _dep
