from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings

settings = get_settings()

if settings.is_sqlite:
    _connect_args: dict = {"check_same_thread": False}
    _engine_kwargs: dict = {}
else:
    # Managed Postgres (Supabase): TLS is required, and statement_cache_size=0
    # keeps asyncpg working through PgBouncer (Supabase's connection pooler).
    _connect_args = {"ssl": "require", "statement_cache_size": 0}
    _engine_kwargs = {"pool_pre_ping": True, "pool_size": 5, "max_overflow": 5}

engine = create_async_engine(
    settings.database_url,
    echo=settings.sql_echo,
    connect_args=_connect_args,
    **_engine_kwargs,
)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncIterator[AsyncSession]:
    # AppError is a rendered response, not a crash: commit so side effects that
    # must persist through a rejection (OTP attempt counter, refresh-token reuse
    # revocation) are kept. Roll back only on unexpected failures.
    from app.errors import AppError

    async with SessionLocal() as session:
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
