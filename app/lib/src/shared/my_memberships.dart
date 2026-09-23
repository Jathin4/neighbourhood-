import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';

/// One of the caller's own community memberships, with its *effective*
/// capabilities already resolved server-side (role's base caps + any extra
/// granted ones) — see rbac.effective_community_caps. This is what a
/// Committee Member's screen keys off, per §1: "capability-based rather
/// than UI-only role checks".
class MyMembership {
  MyMembership({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.role,
    required this.status,
    required this.verificationStatus,
    required this.capabilities,
    this.unitId,
  });

  final String id, communityId, communityName, role, status, verificationStatus;
  final List<String> capabilities;
  final String? unitId;

  bool has(String capability) => capabilities.contains(capability);

  factory MyMembership.fromJson(Map<String, dynamic> j) => MyMembership(
        id: j['id'] as String,
        communityId: j['community_id'] as String,
        communityName: j['community_name'] as String,
        role: j['role'] as String,
        status: j['status'] as String,
        verificationStatus: j['verification_status'] as String,
        capabilities: (j['capabilities'] as List? ?? []).cast<String>(),
        unitId: j['unit_id'] as String?,
      );
}

/// GET /users/me/memberships
final myMembershipsProvider = FutureProvider<List<MyMembership>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/users/me/memberships');
    return (res.data as List)
        .map((e) => MyMembership.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// The community this user is an active member of, used to scope
/// Notices/Issues/Events on the Resident portal. Residents typically belong
/// to just one; the first active membership wins if there's more than one.
final myActiveMembershipProvider = Provider<AsyncValue<MyMembership?>>((ref) {
  return ref.watch(myMembershipsProvider).whenData((list) {
    for (final m in list) {
      if (m.status == 'active') return m;
    }
    return null;
  });
});

/// Same idea, filtered to a specific role — e.g. Community Admin's tab shell
/// scopes its Overview/Residents/Notices tabs to the first community it
/// actively administers.
final firstActiveMembershipForRoleProvider =
    Provider.family<AsyncValue<MyMembership?>, String>((ref, role) {
  return ref.watch(myMembershipsProvider).whenData((list) {
    for (final m in list) {
      if (m.status == 'active' && m.role == role) return m;
    }
    return null;
  });
});

class CommunityMember {
  CommunityMember({required this.id, required this.role, required this.status});
  final String id, role, status;

  factory CommunityMember.fromJson(Map<String, dynamic> j) => CommunityMember(
        id: j['id'] as String,
        role: j['role'] as String,
        status: j['status'] as String,
      );
}

/// GET /communities/{id}/members — every membership in a community (any
/// status), for whoever holds community.member.manage there.
final communityMembersProvider =
    FutureProvider.family<List<CommunityMember>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/communities/$communityId/members');
    return (res.data as List)
        .map((e) => CommunityMember.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});
