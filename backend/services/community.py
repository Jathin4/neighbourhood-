import csv
import io
import re
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app import rbac
from app.enums import CommunityRole, MembershipStatus, VerificationStatus
from app.errors import AppError, not_found
from models.community import Community, Unit
from models.community_content import Event, EventRsvp, Notice, NoticeRead
from models.membership import Membership
from models.user import User
from schemas.community import ImportRowResult, ImportSummary

_MOBILE_RE = re.compile(r"^\+?[1-9]\d{7,14}$")
_REQUIRED_CSV_COLUMNS = {"name", "mobile", "tower", "unit"}


_MAX_GENERATED_UNITS = 5000


async def create_community(db: AsyncSession, data: dict) -> Community:
    data = dict(data)
    towers = data.pop("towers", 0)
    floors = data.pop("floors_per_tower", 0)
    flats = data.pop("flats_per_floor", 0)

    if towers and floors and flats:
        data["settings"] = {
            **data.get("settings", {}),
            "towers": towers,
            "floors_per_tower": floors,
            "flats_per_floor": flats,
        }

    community = Community(**data)
    db.add(community)
    await db.flush()

    if towers and floors and flats:
        await generate_units(db, community.id, towers, floors, flats)

    return community


def _tower_label(index: int) -> str:
    """0 -> 'A', 25 -> 'Z', 26 -> 'AA', ..."""
    label = ""
    index += 1
    while index > 0:
        index, rem = divmod(index - 1, 26)
        label = chr(ord("A") + rem) + label
    return label


async def generate_units(
    db: AsyncSession,
    community_id: uuid.UUID,
    towers: int,
    floors_per_tower: int,
    flats_per_floor: int,
) -> int:
    total = towers * floors_per_tower * flats_per_floor
    if total > _MAX_GENERATED_UNITS:
        raise AppError(
            "too_many_units",
            f"That configuration would create {total} units (max {_MAX_GENERATED_UNITS})",
            400,
        )
    created = 0
    for t in range(towers):
        tower = _tower_label(t)
        for floor in range(1, floors_per_tower + 1):
            for flat in range(1, flats_per_floor + 1):
                unit_number = f"{floor}{flat:02d}"
                _, is_new = await get_or_create_unit(db, community_id, tower, unit_number)
                if is_new:
                    created += 1
    return created


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

    if "capabilities" in changes:
        extra = set(changes["capabilities"] or [])
        if not extra.issubset(rbac.ASSIGNABLE_COMMITTEE_CAPS):
            raise AppError(
                "invalid_capabilities",
                f"Capabilities must be a subset of {sorted(rbac.ASSIGNABLE_COMMITTEE_CAPS)}",
                400,
            )

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


async def create_notice(
    db: AsyncSession, community_id: uuid.UUID, created_by: uuid.UUID, data: dict
) -> Notice:
    notice = Notice(community_id=community_id, created_by=created_by, **data)
    db.add(notice)
    await db.flush()
    return notice


async def list_notices(db: AsyncSession, community_id: uuid.UUID, user_id: uuid.UUID) -> list[dict]:
    notices = list(
        await db.scalars(
            select(Notice)
            .where(Notice.community_id == community_id)
            .order_by(Notice.created_at.desc())
        )
    )
    if not notices:
        return []
    read_ids = set(
        await db.scalars(
            select(NoticeRead.notice_id).where(
                NoticeRead.user_id == user_id,
                NoticeRead.notice_id.in_([n.id for n in notices]),
            )
        )
    )
    return [
        {
            "id": n.id,
            "title": n.title,
            "body": n.body,
            "priority": n.priority,
            "created_at": n.created_at,
            "read": n.id in read_ids,
        }
        for n in notices
    ]


async def mark_notice_read(db: AsyncSession, notice_id: uuid.UUID, user_id: uuid.UUID) -> None:
    existing = await db.scalar(
        select(NoticeRead).where(NoticeRead.notice_id == notice_id, NoticeRead.user_id == user_id)
    )
    if existing is None:
        db.add(NoticeRead(notice_id=notice_id, user_id=user_id))
        await db.flush()


async def create_event(
    db: AsyncSession, community_id: uuid.UUID, created_by: uuid.UUID, data: dict
) -> Event:
    event = Event(community_id=community_id, created_by=created_by, **data)
    db.add(event)
    await db.flush()
    return event


async def list_events(db: AsyncSession, community_id: uuid.UUID, user_id: uuid.UUID) -> list[dict]:
    events = list(
        await db.scalars(
            select(Event).where(Event.community_id == community_id).order_by(Event.starts_at)
        )
    )
    if not events:
        return []
    event_ids = [e.id for e in events]
    counts = dict(
        (
            await db.execute(
                select(EventRsvp.event_id, func.count())
                .where(EventRsvp.event_id.in_(event_ids))
                .group_by(EventRsvp.event_id)
            )
        ).all()
    )
    mine = set(
        await db.scalars(
            select(EventRsvp.event_id).where(
                EventRsvp.user_id == user_id, EventRsvp.event_id.in_(event_ids)
            )
        )
    )
    return [
        {
            "id": e.id,
            "title": e.title,
            "starts_at": e.starts_at,
            "location": e.location,
            "rsvp_count": counts.get(e.id, 0),
            "rsvped": e.id in mine,
        }
        for e in events
    ]


async def toggle_rsvp(db: AsyncSession, event_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    """Returns the new rsvped state."""
    existing = await db.scalar(
        select(EventRsvp).where(EventRsvp.event_id == event_id, EventRsvp.user_id == user_id)
    )
    if existing is not None:
        await db.delete(existing)
        await db.flush()
        return False
    db.add(EventRsvp(event_id=event_id, user_id=user_id))
    await db.flush()
    return True
