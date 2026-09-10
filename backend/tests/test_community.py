import pytest

pytestmark = pytest.mark.asyncio


def _h(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def _make_community(client, superadmin_token, name="Green Meadows") -> str:
    r = await client.post(
        "/api/v1/communities", headers=_h(superadmin_token), json={"name": name}
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def test_superadmin_creates_community_and_units(client, superadmin_token):
    cid = await _make_community(client, superadmin_token)

    r = await client.post(
        f"/api/v1/communities/{cid}/units",
        headers=_h(superadmin_token),
        json={
            "units": [
                {"tower": "A", "unit_number": "101"},
                {"tower": "A", "unit_number": "102"},
            ]
        },
    )
    assert r.status_code == 201
    assert len(r.json()) == 2

    # duplicate tower/unit is ignored, not errored
    r = await client.post(
        f"/api/v1/communities/{cid}/units",
        headers=_h(superadmin_token),
        json={"units": [{"tower": "A", "unit_number": "101"}]},
    )
    assert r.status_code == 201
    assert r.json() == []


async def test_membership_request_then_admin_approves(client, superadmin_token, resident_token):
    cid = await _make_community(client, superadmin_token)

    r = await client.post(
        f"/api/v1/communities/{cid}/members", headers=_h(resident_token), json={}
    )
    assert r.status_code == 201
    membership_id = r.json()["id"]
    assert r.json()["status"] == "pending"

    # resident cannot see the member list
    r = await client.get(f"/api/v1/communities/{cid}/members", headers=_h(resident_token))
    assert r.status_code == 403

    # platform/admin approves
    r = await client.patch(
        f"/api/v1/communities/{cid}/members/{membership_id}",
        headers=_h(superadmin_token),
        json={"status": "active", "role": "community_admin"},
    )
    assert r.status_code == 200
    assert r.json()["status"] == "active"
    assert r.json()["verification_status"] == "verified"

    # now the resident is a member and can read the community
    r = await client.get(f"/api/v1/communities/{cid}", headers=_h(resident_token))
    assert r.status_code == 200


async def test_cross_community_isolation(client, superadmin_token, resident_token):
    c1 = await _make_community(client, superadmin_token, "One")
    c2 = await _make_community(client, superadmin_token, "Two")

    # resident becomes admin of c1 only
    r = await client.post(f"/api/v1/communities/{c1}/members", headers=_h(resident_token), json={})
    mid = r.json()["id"]
    await client.patch(
        f"/api/v1/communities/{c1}/members/{mid}",
        headers=_h(superadmin_token),
        json={"status": "active", "role": "community_admin"},
    )

    # can manage c1 units
    r = await client.post(
        f"/api/v1/communities/{c1}/units",
        headers=_h(resident_token),
        json={"units": [{"tower": "A", "unit_number": "1"}]},
    )
    assert r.status_code == 201

    # cannot manage c2 units
    r = await client.post(
        f"/api/v1/communities/{c2}/units",
        headers=_h(resident_token),
        json={"units": [{"tower": "A", "unit_number": "1"}]},
    )
    assert r.status_code == 403


async def test_csv_resident_import(client, superadmin_token):
    cid = await _make_community(client, superadmin_token)
    csv_bytes = (
        b"name,mobile,tower,unit,relationship\n"
        b"Asha Rao,+919812345678,A,101,owner\n"
        b"Bad Row,not-a-number,A,102,tenant\n"
        b"Ravi K,+919812345679,B,201,\n"
    )

    r = await client.post(
        f"/api/v1/communities/{cid}/members/import",
        headers=_h(superadmin_token),
        files={"file": ("residents.csv", csv_bytes, "text/csv")},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["created"] == 2
    assert body["errors"] == 1

    r = await client.get(
        f"/api/v1/communities/{cid}/members?status=pending", headers=_h(superadmin_token)
    )
    assert len(r.json()) == 2
