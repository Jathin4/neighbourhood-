import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/communities.dart';
import 'panel_data.dart';

class _Membership {
  _Membership(this.id, this.role, this.status);
  final String id, role, status;

  factory _Membership.fromJson(Map<String, dynamic> j) =>
      _Membership(j['id'] as String, j['role'] as String, j['status'] as String);
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

/// PATCH /communities/{id} (configure/activate-deactivate) + membership role
/// management ("manage admins") — both real, per §7's Communities module.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({required this.communityId, required this.name, this.address,
      this.status = 'active', super.key});

  final String communityId;
  final String name;
  final String? address;
  final String status;

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  late final _name = TextEditingController(text: widget.name);
  late final _address = TextEditingController(text: widget.address ?? '');
  late String _status = widget.status;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).raw.patch('/communities/${widget.communityId}', data: {
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'status': _status,
      });
      ref.invalidate(communitiesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Community updated')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateMember(String membershipId, {String? role, String? status}) async {
    try {
      await ref.read(apiClientProvider).raw.patch(
        '/communities/${widget.communityId}/members/$membershipId',
        data: {if (role != null) 'role': role, if (status != null) 'status': status},
      );
      ref.invalidate(_membersProvider(widget.communityId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(_membersProvider(widget.communityId));

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: AppBar(
        backgroundColor: AC.surface,
        surfaceTintColor: AC.surface,
        foregroundColor: AC.ink900,
        title: Text(widget.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configure', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _address, decoration: const InputDecoration(labelText: 'Address')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'suspended', child: Text('Suspended (deactivated)')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Members & admins', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Text('No members yet.')
                : Column(
                    children: [
                      for (final m in list)
                        Card(
                          child: ListTile(
                            title: Text('Membership ${m.id.substring(0, 8)}'),
                            subtitle: Text('${m.role} · ${m.status}'),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                if (m.status == 'pending') ...[
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: AC.green),
                                    tooltip: 'Approve',
                                    onPressed: () => _updateMember(m.id, status: 'active'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: AC.red),
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
                                  onSelected: (role) => _updateMember(m.id, role: role),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
