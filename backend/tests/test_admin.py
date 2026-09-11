import pytest

pytestmark = pytest.mark.asyncio


def _h(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def test_resident_cannot_list_users(client, resident_token):
    r = await client.get("/api/v1/admin/users", headers=_h(resident_token))
    assert r.status_code == 403


async def test_platform_ops_can_search_and_suspend_users(
    client, platform_ops_token, resident_token
):
    # resident_token fixture already created the user; search for it.
    r = await client.get(
        "/api/v1/admin/users",
        headers=_h(platform_ops_token),
        params={"search": "+919000000001"},
    )
    assert r.status_code == 200
    users = r.json()
    assert len(users) == 1
    user_id = users[0]["id"]
    assert users[0]["status"] == "pending"

    r = await client.patch(
        f"/api/v1/admin/users/{user_id}",
        headers=_h(platform_ops_token),
        json={"status": "suspended"},
    )
    assert r.status_code == 200
    assert r.json()["status"] == "suspended"


async def test_status_filter(client, superadmin_token, resident_token):
    r = await client.get(
        "/api/v1/admin/users",
        headers=_h(superadmin_token),
        params={"status": "active"},
    )
    assert r.status_code == 200
    # resident is still 'pending'; superadmin itself is 'active'.
    assert all(u["status"] == "active" for u in r.json())


async def test_only_super_admin_can_view_audit_logs(client, platform_ops_token, superadmin_token):
    r = await client.get("/api/v1/admin/audit-logs", headers=_h(platform_ops_token))
    assert r.status_code == 403

    r = await client.get("/api/v1/admin/audit-logs", headers=_h(superadmin_token))
    assert r.status_code == 200


async def test_sensitive_actions_show_up_in_audit_log(client, superadmin_token):
    r = await client.post(
        "/api/v1/communities", headers=_h(superadmin_token), json={"name": "Audit Test Community"}
    )
    assert r.status_code == 201
    community_id = r.json()["id"]

    r = await client.get("/api/v1/admin/audit-logs", headers=_h(superadmin_token))
    assert r.status_code == 200
    logs = r.json()
    match = next(entry for entry in logs if entry["action"] == "community.create")
    assert match["entity_id"] == community_id
    assert match["actor_mobile"] == "+919000000009"
