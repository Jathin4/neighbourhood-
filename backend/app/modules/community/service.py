import csv
import io
import re
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.enums import CommunityRole, MembershipStatus, VerificationStatus
from app.errors import AppError, not_found
from app.models.community import Community, Unit
from app.models.membership import Membership
from app.models.user import User
from app.modules.community.schemas import ImportRowResult, ImportSummary

_MOBILE_RE = re.compile(r"^\+?[1-9]\d{7,14}$")
_REQUIRED_CSV_COLUMNS = {"name", "mobile", "tower", "unit"}


async def create_community(db: AsyncSession, data: dict) -> Community:
    community = Community(**data)
    db.add(community)
    await db.flush()
    return community


async def get_community(db: AsyncSession, community_id: uuid.UUID) -> Community:
    community = await db.get(Community, community_id)
    if community is None:
        raise not_found("Community")
    return community


async def update_community(db: AsyncSession, community_id: uuid.UUID, changes: dict) -> Community:
    community = await get_community(db, community_id)
    for field, value in changes.items():
        setattr(community, field, value)
    await db.flush()
    return community


async def get_or_create_unit(
    db: AsyncSession, community_id: uuid.UUID, tower: str, unit_number: str
) -> tuple[Unit, bool]:
    existing = await db.scalar(
        select(Unit).where(
            Unit.community_id == community_id,
            Unit.tower == tower,
            Unit.unit_number == unit_number,
        )
    )
    if existing:
        return existing, False
    unit = Unit(community_id=community_id, tower=tower, unit_number=unit_number)
    db.add(unit)
    await db.flush()
    return unit, True


async def add_units(db: AsyncSession, community_id: uuid.UUID, units: list[dict]) -> list[Unit]:
    await get_community(db, community_id)
    created: list[Unit] = []
    for u in units:
        unit, is_new = await get_or_create_unit(db, community_id, u["tower"], u["unit_number"])
        if is_new:
            created.append(unit)
    return created


async def list_units(db: AsyncSession, community_id: uuid.UUID) -> list[Unit]:
    q = (
        select(Unit)
        .where(Unit.community_id == community_id)
        .order_by(Unit.tower, Unit.unit_number)
    )
    return list(await db.scalars(q))


async def request_membership(
    db: AsyncSession,
    community_id: uuid.UUID,
    user_id: uuid.UUID,
    unit_id: uuid.UUID | None,
    relationship: str | None,
) -> Membership:
    await get_community(db, community_id)
    existing = await db.scalar(
        select(Membership).where(
            Membership.user_id == user_id, Membership.community_id == community_id
        )
    )
    if existing is not None:
        raise AppError("membership_exists", "Membership already requested or active", 409)
    membership = Membership(
        user_id=user_id,
        community_id=community_id,
        unit_id=unit_id,
        household_relationship=relationship,
        role=CommunityRole.resident,
        status=MembershipStatus.pending,
    )
    db.add(membership)
    await db.flush()
    return membership


async def list_memberships(
    db: AsyncSession, community_id: uuid.UUID, status: str | None
) -> list[Membership]:
    q = select(Membership).where(Membership.community_id == community_id)
    if status:
        q = q.where(Membership.status == status)
    return list(await db.scalars(q.order_by(Membership.created_at)))


async def update_membership(
    db: AsyncSession, community_id: uuid.UUID, membership_id: uuid.UUID, changes: dict
) -> Membership:
    membership = await db.get(Membership, membership_id)
    if membership is None or membership.community_id != community_id:
        raise not_found("Membership")

    if changes.get("status") == MembershipStatus.active:
        membership.verification_status = VerificationStatus.verified
    for field, value in changes.items():
        setattr(membership, field, value)
    await db.flush()

    # Keep the user's account state in step when their first community approves them.
    if membership.status == MembershipStatus.active:
        user = await db.get(User, membership.user_id)
        if user and user.status == "pending":
            user.status = "active"
            await db.flush()
    return membership


async def import_residents_csv(
    db: AsyncSession, community_id: uuid.UUID, raw: bytes
) -> ImportSummary:
    await get_community(db, community_id)
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        raise AppError("csv_encoding", "CSV must be UTF-8 encoded", 400) from None

    reader = csv.DictReader(io.StringIO(text))
    headers = {h.strip().lower() for h in (reader.fieldnames or [])}
    missing = _REQUIRED_CSV_COLUMNS - headers
    if missing:
        raise AppError("csv_columns", f"Missing required columns: {sorted(missing)}", 400)

    results: list[ImportRowResult] = []
    created = existing = errors = 0

    for i, row in enumerate(reader, start=2):  # row 1 is the header
        row = {(k or "").strip().lower(): (v or "").strip() for k, v in row.items()}
        mobile = row.get("mobile", "")
        try:
            if not _MOBILE_RE.match(mobile):
                raise ValueError("invalid mobile")
            if not row.get("tower") or not row.get("unit"):
                raise ValueError("tower and unit are required")

            user = await db.scalar(select(User).where(User.mobile == mobile))
            if user is None:
                user = User(mobile=mobile, name=row.get("name") or None)
                db.add(user)
                await db.flush()

            unit, _ = await get_or_create_unit(db, community_id, row["tower"], row["unit"])

            membership = await db.scalar(
                select(Membership).where(
                    Membership.user_id == user.id, Membership.community_id == community_id
                )
            )
            if membership is not None:
                existing += 1
                results.append(ImportRowResult(row=i, mobile=mobile, outcome="exists"))
                continue

            db.add(
                Membership(
                    user_id=user.id,
                    community_id=community_id,
                    unit_id=unit.id,
                    role=CommunityRole.resident,
                    status=MembershipStatus.pending,
                    household_relationship=row.get("relationship") or None,
                )
            )
            await db.flush()
            created += 1
            results.append(ImportRowResult(row=i, mobile=mobile, outcome="created"))
        except ValueError as exc:
            errors += 1
            results.append(
                ImportRowResult(row=i, mobile=mobile or None, outcome="error", detail=str(exc))
            )

    return ImportSummary(
        total=created + existing + errors,
        created=created,
        existing=existing,
        errors=errors,
        results=results,
    )
