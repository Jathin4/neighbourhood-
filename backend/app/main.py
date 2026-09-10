import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import errors
from app.api import api_v1
from app.config import get_settings
from app.db import Base, engine
from app.models import *  # noqa: F401,F403  (register mappers on Base.metadata)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Local SQLite convenience: auto-create the schema. Postgres always uses Alembic.
    if settings.is_sqlite:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
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
