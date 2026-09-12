import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';

class _Membership {
  _Membership(this.id, this.role, this.status, this.capabilities);
  final String id, role, status;
  final List<String> capabilities;

  factory _Membership.fromJson(Map<String, dynamic> j) => _Membership(
        j['id'] as String,
        j['role'] as String,
        j['status'] as String,
        (j['capabilities'] as List? ?? []).cast<String>(),
      );
}

final _membersProvider =
    FutureProvider.autoDispose.family<List<_Membership>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/communities/$communityId/members');
    return (res.data as List).map((e) => _Membership.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// Assignable to a Committee Member (must match backend rbac.ASSIGNABLE_COMMITTEE_CAPS).
const _assignableCaps = {
  'community.unit.manage': 'Manage units',
  'community.member.manage': 'Manage members',
  'community.resident.import': 'Import residents (CSV)',
};

/// Approve/reject membership requests + assign admin/committee permissions
/// (§6). Reused by Community Admin (via CommunityDetailScreen) and directly
/// by Committee Members who hold community.member.manage.
class MembersManagementScreen extends ConsumerStatefulWidget {
  const MembersManagementScreen({required this.communityId, required this.communityName, super.key});

  final String communityId;
  final String communityName;

  @override
  ConsumerState<MembersManagementScreen> createState() => _MembersManagementScreenState();
}

class _MembersManagementScreenState extends ConsumerState<MembersManagementScreen> {
  Future<void> _updateMember(String membershipId,
      {String? role, String? status, List<String>? capabilities}) async {
    try {
      await ref.read(apiClientProvider).raw.patch(
        '/communities/${widget.communityId}/members/$membershipId',
        data: {
          if (role != null) 'role': role,
          if (status != null) 'status': status,
          if (capabilities != null) 'capabilities': capabilities,
        },
      );
      ref.invalidate(_membersProvider(widget.communityId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
      }
    }
  }

  Future<void> _setRole(_Membership m, String role) async {
    if (role != 'committee_member') {
      await _updateMember(m.id, role: role, capabilities: role == m.role ? null : const []);
      return;
    }
    final chosen = await _pickCapabilities(Set.of(m.capabilities));
    if (chosen != null) {
      await _updateMember(m.id, role: role, capabilities: chosen.toList());
    }
  }

  Future<Set<String>?> _pickCapabilities(Set<String> initial) {
    final selected = Set.of(initial);
    return showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Committee Member capabilities'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in _assignableCaps.entries)
                CheckboxListTile(
                  value: selected.contains(entry.key),
                  title: Text(entry.value),
                  onChanged: (v) => setState(
                    () => v == true ? selected.add(entry.key) : selected.remove(entry.key),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(_membersProvider(widget.communityId));

    return Scaffold(
      appBar: AppBar(title: Text('Members — ${widget.communityName}')),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No members yet.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final m in list)
                    Card(
                      child: ListTile(
                        title: Text('Membership ${m.id.substring(0, 8)}'),
                        subtitle: Text(
                          m.role == 'committee_member' && m.capabilities.isNotEmpty
                              ? '${m.role} · ${m.status} · ${m.capabilities.join(", ")}'
                              : '${m.role} · ${m.status}',
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            if (m.status == 'pending') ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                tooltip: 'Approve',
                                onPressed: () => _updateMember(m.id, status: 'active'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'Reject',
                                onPressed: () => _updateMember(m.id, status: 'rejected'),
                              ),
                            ],
                            PopupMenuButton<String>(
                              tooltip: 'Set role',
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'resident', child: Text('Resident')),
                                PopupMenuItem(
                                    value: 'committee_member', child: Text('Committee Member')),
                                PopupMenuItem(
                                    value: 'community_admin', child: Text('Community Admin')),
                              ],
                              onSelected: (role) => _setRole(m, role),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
