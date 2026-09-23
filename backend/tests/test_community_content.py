import pytest

pytestmark = pytest.mark.asyncio


def _h(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def _make_community(client, superadmin_token, name="Green Meadows") -> str:
    r = await client.post("/api/v1/communities", headers=_h(superadmin_token), json={"name": name})
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _join_and_activate(client, superadmin_token, token, community_id, role="resident"):
    r = await client.post(f"/api/v1/communities/{community_id}/members", headers=_h(token), json={})
    membership_id = r.json()["id"]
    r = await client.patch(
        f"/api/v1/communities/{community_id}/members/{membership_id}",
        headers=_h(superadmin_token),
        json={"status": "active", "role": role},
    )
    assert r.status_code == 200, r.text


async def _login(client, mobile: str) -> str:
    await client.post("/api/v1/auth/otp/request", json={"mobile": mobile})
    r = await client.post("/api/v1/auth/otp/verify", json={"mobile": mobile, "code": "123456"})
    return r.json()["access_token"]


async def test_notice_lifecycle(client, superadmin_token, resident_token):
    community_id = await _make_community(client, superadmin_token, "Notice Test")
    admin_token = await _login(client, "+919444000001")
    await _join_and_activate(client, superadmin_token, admin_token, community_id, "community_admin")
    await _join_and_activate(client, superadmin_token, resident_token, community_id)

    r = await client.post(
        f"/api/v1/communities/{community_id}/notices",
        headers=_h(admin_token),
        json={"title": "Water cut", "body": "10am-2pm", "priority": "critical"},
    )
    assert r.status_code == 201, r.text
    notice_id = r.json()["id"]
    assert r.json()["read"] is True  # the author already "knows" it

    r = await client.get(f"/api/v1/communities/{community_id}/notices", headers=_h(resident_token))
    assert r.status_code == 200
    notices = r.json()
    assert len(notices) == 1
    assert notices[0]["read"] is False

    r = await client.post(
        f"/api/v1/communities/{community_id}/notices/{notice_id}/read", headers=_h(resident_token)
    )
    assert r.status_code == 204

    r = await client.get(f"/api/v1/communities/{community_id}/notices", headers=_h(resident_token))
    assert r.json()[0]["read"] is True


async def test_resident_cannot_create_a_notice(client, superadmin_token, resident_token):
    community_id = await _make_community(client, superadmin_token, "Notice Perm Test")
    await _join_and_activate(client, superadmin_token, resident_token, community_id)
    r = await client.post(
        f"/api/v1/communities/{community_id}/notices",
        headers=_h(resident_token),
        json={"title": "x", "body": "y"},
    )
    assert r.status_code == 403


async def test_event_rsvp_toggle(client, superadmin_token, resident_token):
    community_id = await _make_community(client, superadmin_token, "Event Test")
    admin_token = await _login(client, "+919444000002")
    await _join_and_activate(client, superadmin_token, admin_token, community_id, "community_admin")
    await _join_and_activate(client, superadmin_token, resident_token, community_id)

    r = await client.post(
        f"/api/v1/communities/{community_id}/events",
        headers=_h(admin_token),
        json={"title": "Diwali night", "starts_at": "2026-10-20T19:00:00Z", "location": "Hall"},
    )
    assert r.status_code == 201, r.text
    event_id = r.json()["id"]
    assert r.json()["rsvp_count"] == 0

    r = await client.post(
        f"/api/v1/communities/{community_id}/events/{event_id}/rsvp", headers=_h(resident_token)
    )
    assert r.status_code == 200
    assert r.json()["rsvped"] is True

    r = await client.get(f"/api/v1/communities/{community_id}/events", headers=_h(resident_token))
    assert r.json()[0]["rsvp_count"] == 1
    assert r.json()[0]["rsvped"] is True

    r = await client.post(
        f"/api/v1/communities/{community_id}/events/{event_id}/rsvp", headers=_h(resident_token)
    )
    assert r.json()["rsvped"] is False


async def test_issue_lifecycle(client, superadmin_token, resident_token):
    community_id = await _make_community(client, superadmin_token, "Issue Test")
    admin_token = await _login(client, "+919444000003")
    await _join_and_activate(client, superadmin_token, admin_token, community_id, "community_admin")
    await _join_and_activate(client, superadmin_token, resident_token, community_id)

    r = await client.post(
        "/api/v1/issues",
        headers=_h(resident_token),
        json={"community_id": community_id, "category": "issue", "title": "Lift broken"},
    )
    assert r.status_code == 201, r.text
    issue_id = r.json()["id"]
    assert r.json()["status"] == "submitted"
    assert r.json()["raised_by_name"]

    r = await client.get(f"/api/v1/issues?community_id={community_id}", headers=_h(admin_token))
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = await client.patch(f"/api/v1/issues/{issue_id}", headers=_h(admin_token), json={"action": "start"})
    assert r.status_code == 200
    assert r.json()["status"] == "in_progress"

    r = await client.patch(
        f"/api/v1/issues/{issue_id}", headers=_h(admin_token), json={"action": "resolve"}
    )
    assert r.json()["status"] == "resolved"

    r = await client.get("/api/v1/issues/mine", headers=_h(resident_token))
    assert r.json()[0]["status"] == "resolved"

    r = await client.patch(
        f"/api/v1/issues/{issue_id}", headers=_h(resident_token), json={"action": "reopen"}
    )
    assert r.status_code == 200
    assert r.json()["status"] == "reopened"


async def test_resident_cannot_resolve_issues_or_view_community_queue(
    client, superadmin_token, resident_token
):
    community_id = await _make_community(client, superadmin_token, "Issue Perm Test")
    await _join_and_activate(client, superadmin_token, resident_token, community_id)

    r = await client.post(
        "/api/v1/issues",
        headers=_h(resident_token),
        json={"community_id": community_id, "category": "issue", "title": "Noise complaint"},
    )
    issue_id = r.json()["id"]

    r = await client.get(f"/api/v1/issues?community_id={community_id}", headers=_h(resident_token))
    assert r.status_code == 403

    r = await client.patch(
        f"/api/v1/issues/{issue_id}", headers=_h(resident_token), json={"action": "resolve"}
    )
    assert r.status_code == 403
