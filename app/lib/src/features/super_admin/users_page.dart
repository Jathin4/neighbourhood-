import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import 'panel_data.dart';

class _AdminUser {
  _AdminUser(this.id, this.mobile, this.name, this.status, this.platformRole);
  final String id, mobile, status;
  final String? name, platformRole;

  factory _AdminUser.fromJson(Map<String, dynamic> j) => _AdminUser(
        j['id'] as String,
        j['mobile'] as String,
        j['name'] as String?,
        j['status'] as String,
        j['platform_role'] as String?,
      );
}

/// GET/PATCH /admin/users — real, requires user.manage (platform_ops/super_admin).
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _search = TextEditingController();
  String? _statusFilter;
  List<_AdminUser>? _users;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiClientProvider).raw.get('/admin/users', queryParameters: {
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        if (_statusFilter != null) 'status': _statusFilter,
      });
      setState(() {
        _users = (res.data as List)
            .map((e) => _AdminUser.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      setState(() => _error = AppException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(_AdminUser user, String status) async {
    try {
      await ref.read(apiClientProvider).raw.patch('/admin/users/${user.id}', data: {
        'status': status,
      });
      _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
      children: [
        const Text('All Users',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AC.ink900)),
        const SizedBox(height: 4),
        const Text('Search, view, suspend or reactivate accounts.',
            style: TextStyle(fontSize: 14, color: AC.ink600)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by mobile or name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String?>(
              value: _statusFilter,
              hint: const Text('Any status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Any status')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v);
                _load();
              },
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: _load, child: const Text('Search')),
          ],
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AC.red))
        else if (_users == null || _users!.isEmpty)
          const Text('No users match.')
        else
          Container(
            decoration: BoxDecoration(
              color: AC.surface,
              border: Border.all(color: AC.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (final u in _users!)
                  ListTile(
                    title: Text(u.name ?? u.mobile,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${u.mobile}${u.platformRole != null ? ' · ${u.platformRole}' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusPill(u.status),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'active', child: Text('Set Active')),
                            PopupMenuItem(value: 'suspended', child: Text('Suspend')),
                            PopupMenuItem(value: 'rejected', child: Text('Reject')),
                            PopupMenuItem(value: 'deactivated', child: Text('Deactivate')),
                          ],
                          onSelected: (status) => _setStatus(u, status),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statusPill(String status) {
    final color = switch (status) {
      'active' => AC.green,
      'pending' => AC.amber,
      _ => AC.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
