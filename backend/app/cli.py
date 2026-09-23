"""Small admin CLI.

    python -m app.cli seed-superadmin +919999999999
    python -m app.cli create-schema
"""
import asyncio
import sys

from sqlalchemy import select

from app.db import Base, SessionLocal, engine
from app.enums import AccountStatus, PlatformRole
from models import User


async def _create_schema() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("schema created")


async def _seed_superadmin(mobile: str) -> None:
    async with SessionLocal() as db:
        user = await db.scalar(select(User).where(User.mobile == mobile))
        if user is None:
            user = User(mobile=mobile, name="Super Admin")
            db.add(user)
        user.platform_role = PlatformRole.super_admin
        user.status = AccountStatus.active
        await db.commit()
        print(f"super admin ready: {mobile} ({user.id})")


def main() -> None:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        raise SystemExit(1)
    cmd, *rest = args
    if cmd == "create-schema":
        asyncio.run(_create_schema())
    elif cmd == "seed-superadmin" and rest:
        asyncio.run(_seed_superadmin(rest[0]))
    else:
        print(__doc__)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
