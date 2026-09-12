import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The 6 roles from the requirements doc (§1). Resident/Community Admin/
/// Committee Member/Platform Ops/Super Admin map to real backend roles
/// (`User.platform_role`, per-community `Membership.role`); Service Provider
/// is the standalone demo portal (marketplace/provider isn't built yet).
enum AppRole {
  resident,
  communityAdmin,
  committeeMember,
  provider,
  platformOps,
  superAdmin;

  String get label => switch (this) {
        AppRole.resident => 'Resident',
        AppRole.communityAdmin => 'Community Admin',
        AppRole.committeeMember => 'Committee Member',
        AppRole.provider => 'Service Provider',
        AppRole.platformOps => 'Platform Operations',
        AppRole.superAdmin => 'Super Admin',
      };

  String get description => switch (this) {
        AppRole.resident =>
          'Community, directory, issues, service discovery, bookings, reviews',
        AppRole.communityAdmin =>
          'Residents, notices, issues, polls, events, curated providers',
        AppRole.committeeMember => 'Assigned operational workflows',
        AppRole.provider => 'Profile, services, leads, bookings, availability, reviews',
        AppRole.platformOps =>
          'Verification, moderation, support, provider/category operations',
        AppRole.superAdmin => 'Configuration, finance, RBAC, audit — full platform',
      };

  IconData get icon => switch (this) {
        AppRole.resident => Icons.home_rounded,
        AppRole.communityAdmin => Icons.shield_rounded,
        AppRole.committeeMember => Icons.groups_rounded,
        AppRole.provider => Icons.handyman_rounded,
        AppRole.platformOps => Icons.support_agent_rounded,
        AppRole.superAdmin => Icons.admin_panel_settings_rounded,
      };
}

/// Which role the signed-in user is viewing the app as this session.
/// Reset to null on logout so the picker shows again next sign-in.
final roleProvider = StateProvider<AppRole?>((ref) => null);
