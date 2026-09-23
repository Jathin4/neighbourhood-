"""String-valued enums shared across models and schemas.

Stored as plain strings (portable across SQLite/Postgres); validated in code.
"""
from enum import StrEnum


class AccountStatus(StrEnum):
    pending = "pending"
    active = "active"
    suspended = "suspended"
    rejected = "rejected"
    deactivated = "deactivated"


class PlatformRole(StrEnum):
    platform_ops = "platform_ops"
    super_admin = "super_admin"


class CommunityRole(StrEnum):
    resident = "resident"
    committee_member = "committee_member"
    community_admin = "community_admin"


class MembershipStatus(StrEnum):
    pending = "pending"
    active = "active"
    suspended = "suspended"
    rejected = "rejected"


class VerificationStatus(StrEnum):
    unverified = "unverified"
    verified = "verified"
    rejected = "rejected"


class BookingStatus(StrEnum):
    requested = "requested"
    accepted = "accepted"
    completed = "completed"
    cancelled = "cancelled"


class NoticePriority(StrEnum):
    general = "general"
    critical = "critical"


class IssueStatus(StrEnum):
    submitted = "submitted"
    in_progress = "in_progress"
    resolved = "resolved"
    reopened = "reopened"
