import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';

class _PendingMember {
  _PendingMember({required this.id, this.householdRelationship});

  final String id;
  final String? householdRelationship;

  factory _PendingMember.fromJson(Map<String, dynamic> j) => _PendingMember(
        id: j['id'] as String,
        householdRelationship: j['household_relationship'] as String?,
      );
}

final _pendingMembersProvider =
    FutureProvider.family<List<_PendingMember>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get(
      '/communities/$communityId/members',
      queryParameters: {'status': 'pending'},
    );
    return (res.data as List)
        .map((e) => _PendingMember.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// PATCH /communities/{id}/members/{membershipId} — approve/reject a join request.
class PendingMembersScreen extends ConsumerWidget {
  const PendingMembersScreen({
    required this.communityId,
    required this.communityName,
    super.key,
  });

  final String communityId;
  final String communityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(_pendingMembersProvider(communityId));

    Future<void> decide(String membershipId, String status) async {
      try {
        await ref.read(apiClientProvider).raw.patch(
          '/communities/$communityId/members/$membershipId',
          data: {'status': status},
        );
        ref.invalidate(_pendingMembersProvider(communityId));
      } on DioException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('$communityName — pending requests')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No pending membership requests.'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final m = list[i];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(m.householdRelationship ?? 'Join request'),
                    subtitle: Text('Membership ${m.id.substring(0, 8)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: () => decide(m.id, 'active'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () => decide(m.id, 'rejected'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
