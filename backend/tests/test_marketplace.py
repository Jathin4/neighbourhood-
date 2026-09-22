import pytest

pytestmark = pytest.mark.asyncio


def _h(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


async def _register_provider(client, token, category="Electrician", name="Ramesh Electricals"):
    r = await client.put(
        "/api/v1/marketplace/providers/me",
        headers=_h(token),
        json={"business_name": name, "category": category},
    )
    assert r.status_code == 200, r.text
    return r.json()


async def _book(client, token, category="Electrician", title="Switchboard repair"):
    r = await client.post(
        "/api/v1/bookings", headers=_h(token), json={"category": category, "title": title}
    )
    assert r.status_code == 201, r.text
    return r.json()


async def test_resident_booking_appears_as_a_lead_for_a_matching_provider(
    client, resident_token, provider_token
):
    await _register_provider(client, provider_token)
    booking = await _book(client, resident_token)

    # The provider sees it as an unclaimed lead...
    r = await client.get("/api/v1/bookings/leads", headers=_h(provider_token))
    assert r.status_code == 200
    leads = r.json()
    assert any(lead["id"] == booking["id"] for lead in leads)
    assert leads[0]["resident_name"]  # resident's mobile/name is resolved, not just an id

    # ...and the resident sees their own booking as still "requested".
    r = await client.get("/api/v1/bookings/mine", headers=_h(resident_token))
    mine = r.json()
    assert any(b["id"] == booking["id"] and b["status"] == "requested" for b in mine)


async def test_wrong_category_provider_does_not_see_the_lead(client, resident_token, provider_token):
    await _register_provider(client, provider_token, category="Plumber")
    await _book(client, resident_token, category="Electrician")

    r = await client.get("/api/v1/bookings/leads", headers=_h(provider_token))
    assert r.json() == []


async def test_accept_then_complete_flow_is_visible_to_both_sides(
    client, resident_token, provider_token
):
    await _register_provider(client, provider_token)
    booking = await _book(client, resident_token)

    r = await client.patch(
        f"/api/v1/bookings/{booking['id']}", headers=_h(provider_token), json={"action": "accept"}
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "accepted"

    # A second provider can no longer claim it.
    r = await client.get("/api/v1/bookings/leads", headers=_h(provider_token))
    assert r.json() == []

    r = await client.patch(
        f"/api/v1/bookings/{booking['id']}", headers=_h(provider_token), json={"action": "complete"}
    )
    assert r.status_code == 200
    assert r.json()["status"] == "completed"

    r = await client.get("/api/v1/bookings/mine", headers=_h(resident_token))
    mine = {b["id"]: b for b in r.json()}
    assert mine[booking["id"]]["status"] == "completed"
    assert mine[booking["id"]]["provider_name"]


async def test_resident_can_cancel_an_unclaimed_booking(client, resident_token):
    booking = await _book(client, resident_token)
    r = await client.patch(
        f"/api/v1/bookings/{booking['id']}", headers=_h(resident_token), json={"action": "cancel"}
    )
    assert r.status_code == 200
    assert r.json()["status"] == "cancelled"


async def test_another_provider_cannot_complete_someone_elses_booking(
    client, resident_token, provider_token
):
    await _register_provider(client, provider_token)
    booking = await _book(client, resident_token)
    await client.patch(
        f"/api/v1/bookings/{booking['id']}", headers=_h(provider_token), json={"action": "accept"}
    )

    r = await client.post("/api/v1/auth/otp/request", json={"mobile": "+919000000003"})
    code = r.json()["debug_code"]
    r = await client.post(
        "/api/v1/auth/otp/verify", json={"mobile": "+919000000003", "code": code}
    )
    other_token = r.json()["access_token"]
    await _register_provider(client, other_token, name="Other Electricals")

    r = await client.patch(
        f"/api/v1/bookings/{booking['id']}", headers=_h(other_token), json={"action": "complete"}
    )
    assert r.status_code == 403
