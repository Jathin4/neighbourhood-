import pytest

pytestmark = pytest.mark.asyncio


def _h(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def _make_community(client, superadmin_token, name="Committee Test Community") -> str:
    r = await client.post("/api/v1/communities", headers=_h(superadmin_token), json={"name": name})
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _join_and_activate(
    client, superadmin_token, resident_token, community_id, role="resident"
):
    r = await client.post(
        f"/api/v1/communities/{community_id}/members", headers=_h(resident_token), json={}
    )
    membership_id = r.json()["id"]
    r = await client.patch(
        f"/api/v1/communities/{community_id}/members/{membership_id}",
        headers=_h(superadmin_token),
        json={"status": "active", "role": role},
    )
    assert r.status_code == 200, r.text
    return membership_id


async def test_resident_has_no_capabilities(client, superadmin_token, resident_token):
    community_id = await _make_community(client, superadmin_token)
    await _join_and_activate(client, superadmin_token, resident_token, community_id)

    r = await client.get("/api/v1/users/me/memberships", headers=_h(resident_token))
    assert r.status_code == 200
    mine = r.json()
    assert len(mine) == 1
    assert mine[0]["role"] == "resident"
    assert mine[0]["capabilities"] == []
    assert mine[0]["community_name"] == "Committee Test Community"


async def test_committee_member_gets_only_granted_capabilities(
    client, superadmin_token, resident_token
):
    community_id = await _make_community(client, superadmin_token, "Committee Grant Test")
    membership_id = await _join_and_activate(
        client, superadmin_token, resident_token, community_id, role="committee_member"
    )

    r = await client.patch(
        f"/api/v1/communities/{community_id}/members/{membership_id}",
        headers=_h(superadmin_token),
        json={"capabilities": ["community.member.manage"]},
    )
    assert r.status_code == 200, r.text

    r = await client.get("/api/v1/users/me/memberships", headers=_h(resident_token))
    mine = r.json()[0]
    assert mine["role"] == "committee_member"
    assert mine["capabilities"] == ["community.member.manage"]

    # granted capability actually works: can now manage members in that community
    r = await client.get(
        f"/api/v1/communities/{community_id}/members", headers=_h(resident_token)
    )
    assert r.status_code == 200
    # but not a capability they weren't granted
    r = await client.post(
        f"/api/v1/communities/{community_id}/units",
        headers=_h(resident_token),
        json={"units": [{"tower": "A", "unit_number": "1"}]},
    )
    assert r.status_code == 403


async def test_cannot_grant_a_capability_outside_the_assignable_set(
    client, superadmin_token, resident_token
):
    community_id = await _make_community(client, superadmin_token, "Escalation Test")
    membership_id = await _join_and_activate(
        client, superadmin_token, resident_token, community_id, role="committee_member"
    )

    r = await client.patch(
        f"/api/v1/communities/{community_id}/members/{membership_id}",
        headers=_h(superadmin_token),
        json={"capabilities": ["community.create"]},
    )
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "invalid_capabilities"
