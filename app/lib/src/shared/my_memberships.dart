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
