import os

os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("ENV", "test")
os.environ.setdefault("OTP_DEBUG", "true")

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.enums import AccountStatus, PlatformRole
from app.main import app
from app.models import User

# One shared in-memory DB for the whole test session.
_engine = create_async_engine(
    "sqlite+aiosqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
_Session = async_sessionmaker(_engine, expire_on_commit=False)


@pytest_asyncio.fixture(autouse=True)
async def _schema():
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db():
    async with _Session() as session:
        yield session
        await session.commit()


@pytest_asyncio.fixture
async def client():
    from app.errors import AppError

    async def _get_db():
        async with _Session() as session:
            try:
                yield session
            except AppError:
                await session.commit()
                raise
            except Exception:
                await session.rollback()
                raise
            else:
                await session.commit()

    app.dependency_overrides[get_db] = _get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


async def _login(client: AsyncClient, mobile: str) -> str:
    r = await client.post("/api/v1/auth/otp/request", json={"mobile": mobile})
    code = r.json()["debug_code"]
    r = await client.post("/api/v1/auth/otp/verify", json={"mobile": mobile, "code": code})
    return r.json()["access_token"]


@pytest_asyncio.fixture
async def resident_token(client):
    return await _login(client, "+919000000001")


@pytest_asyncio.fixture
async def superadmin_token(client, db):
    from sqlalchemy import select

    token = await _login(client, "+919000000009")
    u = await db.scalar(select(User).where(User.mobile == "+919000000009"))
    u.platform_role = PlatformRole.super_admin
    u.status = AccountStatus.active
    await db.commit()
    return token
