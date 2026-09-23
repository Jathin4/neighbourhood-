import pytest

from app.enums import AccountStatus, PlatformRole
from app.security import hash_password
from models import User

pytestmark = pytest.mark.asyncio


async def _make_superadmin(db, email: str, password: str) -> None:
    db.add(
        User(
            email=email,
            password_hash=hash_password(password),
            platform_role=PlatformRole.super_admin,
            status=AccountStatus.active,
        )
    )
    await db.commit()


async def test_email_login_issues_tokens(client, db):
    await _make_superadmin(db, "admin@example.com", "correct-horse")
    r = await client.post(
        "/api/v1/auth/login/email", json={"email": "admin@example.com", "password": "correct-horse"}
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["access_token"] and body["refresh_token"]

    r = await client.get(
        "/api/v1/users/me", headers={"Authorization": f"Bearer {body['access_token']}"}
    )
    assert r.status_code == 200
    assert r.json()["platform_role"] == "super_admin"
    assert r.json()["mobile"] is None


async def test_email_login_wrong_password_rejected(client, db):
    await _make_superadmin(db, "admin2@example.com", "correct-horse")
    r = await client.post(
        "/api/v1/auth/login/email", json={"email": "admin2@example.com", "password": "wrong"}
    )
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_credentials"


async def test_email_login_unknown_email_rejected(client):
    r = await client.post(
        "/api/v1/auth/login/email", json={"email": "nobody@example.com", "password": "anything"}
    )
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_credentials"


async def test_otp_account_cannot_log_in_with_email(client, db):
    """A regular resident (no password set) must not be able to log in via
    this path even if they somehow know/guess a matching email."""
    db.add(User(mobile="+919333000001", email="resident@example.com"))
    await db.commit()
    r = await client.post(
        "/api/v1/auth/login/email", json={"email": "resident@example.com", "password": "anything"}
    )
    assert r.status_code == 401
