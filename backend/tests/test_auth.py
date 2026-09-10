import pytest

pytestmark = pytest.mark.asyncio


async def test_otp_request_and_verify_issues_tokens(client):
    r = await client.post("/api/v1/auth/otp/request", json={"mobile": "+919111111111"})
    assert r.status_code == 200
    code = r.json()["debug_code"]
    assert code and len(code) == 6

    r = await client.post(
        "/api/v1/auth/otp/verify", json={"mobile": "+919111111111", "code": code}
    )
    assert r.status_code == 200
    body = r.json()
    assert body["access_token"] and body["refresh_token"]


async def test_wrong_code_rejected(client):
    await client.post("/api/v1/auth/otp/request", json={"mobile": "+919111111112"})
    r = await client.post(
        "/api/v1/auth/otp/verify", json={"mobile": "+919111111112", "code": "000000"}
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "otp_invalid"
    assert r.json()["error"]["correlation_id"]


async def test_protected_endpoint_rejects_anonymous(client):
    r = await client.get("/api/v1/users/me")
    assert r.status_code == 401


async def test_me_and_profile_update(client, resident_token):
    h = {"Authorization": f"Bearer {resident_token}"}
    r = await client.get("/api/v1/users/me", headers=h)
    assert r.status_code == 200
    assert r.json()["status"] == "pending"

    r = await client.patch("/api/v1/users/me", headers=h, json={"name": "Asha"})
    assert r.status_code == 200
    assert r.json()["name"] == "Asha"


async def test_refresh_rotation_and_reuse_detection(client):
    await client.post("/api/v1/auth/otp/request", json={"mobile": "+919111111113"})
    code = (
        await client.post("/api/v1/auth/otp/request", json={"mobile": "+919111111113"})
    ).json()["debug_code"]
    tokens = (
        await client.post(
            "/api/v1/auth/otp/verify", json={"mobile": "+919111111113", "code": code}
        )
    ).json()
    first_refresh = tokens["refresh_token"]

    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": first_refresh})
    assert r.status_code == 200
    new_refresh = r.json()["refresh_token"]
    assert new_refresh != first_refresh

    # reusing the old one is refused
    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": first_refresh})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "refresh_reuse"

    # and the reuse revoked the whole chain
    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh})
    assert r.status_code == 401
