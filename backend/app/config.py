from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# backend/app/config.py -> parents[2] == repo root
REPO_ROOT = Path(__file__).resolve().parents[2]
DB_DIR = REPO_ROOT / "db"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / "backend" / ".env", env_file_encoding="utf-8", extra="ignore"
    )

    env: str = "dev"
    # All application data lives in <repo>/db/tnn.db per project requirement.
    database_url: str = f"sqlite+aiosqlite:///{(DB_DIR / 'tnn.db').as_posix()}"
    sql_echo: bool = False

    jwt_secret: str = "dev-insecure-change-me"
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 15
    refresh_token_ttl_days: int = 30

    otp_ttl_seconds: int = 300
    otp_length: int = 6
    otp_max_attempts: int = 5
    otp_max_requests_per_hour: int = 5
    # When true, the OTP code is returned in the request response and logged (dev only).
    otp_debug: bool = True
    # Fast2SMS "otp" route (fixed template, no DLT registration needed). Unset -> logs to console.
    fast2sms_api_key: str | None = None

    cors_origins: list[str] = ["http://localhost", "http://localhost:3000", "http://localhost:8080"]

    @property
    def is_sqlite(self) -> bool:
        return self.database_url.startswith("sqlite")


@lru_cache
def get_settings() -> Settings:
    DB_DIR.mkdir(parents=True, exist_ok=True)
    return Settings()
