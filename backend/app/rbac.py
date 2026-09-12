"""Capability-based authorization (§1).

Permissions are capabilities, not UI role checks. A request is allowed if the
caller's platform role or their *active* membership role in the target community
grants the required capability (committee members may carry extra per-membership
capabilities).
"""
from app.enums import CommunityRole, PlatformRole

# --- capability catalogue (extend per phase) ---------------------------------
CAP_COMMUNITY_CREATE = "community.create"
CAP_COMMUNITY_UPDATE = "community.update"
CAP_UNIT_MANAGE = "community.unit.manage"
CAP_MEMBER_MANAGE = "community.member.manage"
CAP_RESIDENT_IMPORT = "community.resident.import"
CAP_USER_MANAGE = "user.manage"
CAP_AUDIT_VIEW = "audit.view"

ALL_CAPABILITIES: frozenset[str] = frozenset(
    {
        CAP_COMMUNITY_CREATE,
        CAP_COMMUNITY_UPDATE,
        CAP_UNIT_MANAGE,
        CAP_MEMBER_MANAGE,
        CAP_RESIDENT_IMPORT,
        CAP_USER_MANAGE,
        CAP_AUDIT_VIEW,
    }
)

PLATFORM_ROLE_CAPS: dict[str, frozenset[str]] = {
    # §7: Users + Communities are shared Platform Administration capabilities.
    PlatformRole.platform_ops: frozenset(
        {CAP_COMMUNITY_CREATE, CAP_COMMUNITY_UPDATE, CAP_USER_MANAGE}
    ),
    # §1: audit is called out specifically under Super Admin.
    PlatformRole.super_admin: ALL_CAPABILITIES,
}

COMMUNITY_ROLE_CAPS: dict[str, frozenset[str]] = {
    CommunityRole.resident: frozenset(),
    CommunityRole.committee_member: frozenset(),
    CommunityRole.community_admin: frozenset(
        {CAP_COMMUNITY_UPDATE, CAP_UNIT_MANAGE, CAP_MEMBER_MANAGE, CAP_RESIDENT_IMPORT}
    ),
}

# What a Community Admin may hand a Committee Member (§1: "configurable
# permissions"). Deliberately excludes CAP_COMMUNITY_UPDATE — renaming/
# deactivating the community itself stays admin-only.
ASSIGNABLE_COMMITTEE_CAPS: frozenset[str] = frozenset(
    {CAP_UNIT_MANAGE, CAP_MEMBER_MANAGE, CAP_RESIDENT_IMPORT}
)


def platform_can(platform_role: str | None, capability: str) -> bool:
    if platform_role == PlatformRole.super_admin:
        return True
    return capability in PLATFORM_ROLE_CAPS.get(platform_role or "", frozenset())


def effective_community_caps(role: str, extra_caps: list[str] | None) -> frozenset[str]:
    """A membership's full capability set: its role's base caps plus whatever
    extra per-membership capabilities it's been granted (committee members).
    """
    return COMMUNITY_ROLE_CAPS.get(role, frozenset()) | set(extra_caps or [])


def community_can(role: str, extra_caps: list[str] | None, capability: str) -> bool:
    return capability in effective_community_caps(role, extra_caps)
