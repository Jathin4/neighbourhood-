import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy import select

from app import errors
from app.api import api_v1
from app.config import get_settings
from app.db import Base, SessionLocal, engine
from app.enums import AccountStatus, PlatformRole
from app.models import *  # noqa: F401,F403  (register mappers on Base.metadata)
from app.models.user import User
from app.security import hash_password

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
settings = get_settings()


async def _seed_superadmin() -> None:
    if not settings.superadmin_email or not settings.superadmin_password:
        return
    async with SessionLocal() as db:
        user = await db.scalar(select(User).where(User.email == settings.superadmin_email))
        if user is None:
            user = User(email=settings.superadmin_email, name="Super Admin")
            db.add(user)
        user.password_hash = hash_password(settings.superadmin_password)
        user.platform_role = PlatformRole.super_admin
        user.status = AccountStatus.active
        await db.commit()


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Local SQLite convenience: auto-create the schema. Postgres always uses Alembic.
    if settings.is_sqlite:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    await _seed_superadmin()
    yield


app = FastAPI(title="Trusted Neighbourhood Network API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    # Flutter's web dev server picks a random localhost port, so in dev allow any origin.
    allow_origins=["*"] if settings.env == "dev" else settings.cors_origins,
    allow_credentials=settings.env != "dev",
    allow_methods=["*"],
    allow_headers=["*"],
)

errors.install(app)
app.include_router(api_v1)


@app.get("/health", tags=["meta"])
async def health():
    return {"status": "ok", "env": settings.env}
