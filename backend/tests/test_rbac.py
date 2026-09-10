from app import rbac
from app.enums import CommunityRole, PlatformRole


def test_super_admin_has_everything():
    assert rbac.platform_can(PlatformRole.super_admin, "anything.at.all") is True


def test_platform_ops_scope_is_limited():
    assert rbac.platform_can(PlatformRole.platform_ops, rbac.CAP_COMMUNITY_CREATE) is True
    assert rbac.platform_can(PlatformRole.platform_ops, rbac.CAP_MEMBER_MANAGE) is False


def test_community_admin_caps():
    assert rbac.community_can(CommunityRole.community_admin, [], rbac.CAP_MEMBER_MANAGE) is True
    assert rbac.community_can(CommunityRole.resident, [], rbac.CAP_MEMBER_MANAGE) is False


def test_committee_member_extra_caps_merge():
    assert rbac.community_can(CommunityRole.committee_member, [], rbac.CAP_UNIT_MANAGE) is False
    assert (
        rbac.community_can(
            CommunityRole.committee_member, [rbac.CAP_UNIT_MANAGE], rbac.CAP_UNIT_MANAGE
        )
        is True
    )


async def test_resident_cannot_create_community(client, resident_token):
    r = await client.post(
        "/api/v1/communities",
        headers={"Authorization": f"Bearer {resident_token}"},
        json={"name": "Green Meadows"},
    )
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "forbidden"
