import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';
import 'communities.dart';
import 'members_management_screen.dart';

/// Community configure/activate-deactivate (§7 Communities module). Member
/// and admin/committee-permission management lives in its own screen
/// (members_management_screen.dart) since Committee Members can reach that
/// without community.update — they'd otherwise see a config form they have
/// no permission to save.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({
    required this.communityId,
    required this.name,
    this.address,
    this.status = 'active',
    super.key,
  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Members & admins'),
              subtitle: const Text('Approve requests, assign roles and committee permissions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MembersManagementScreen(
                  communityId: widget.communityId,
                  communityName: widget.name,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
