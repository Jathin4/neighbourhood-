import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/communities.dart';
import '../../shared/community_detail_screen.dart';
import 'create_community_screen.dart';
import 'panel_data.dart';

/// Community Management > Communities — real list with search + tap-through
/// to configure/activate-deactivate/manage-admins (§7 Communities module).
class CommunitiesAdminPage extends ConsumerStatefulWidget {
  const CommunitiesAdminPage({super.key});

  @override
  ConsumerState<CommunitiesAdminPage> createState() => _CommunitiesAdminPageState();
}

class _CommunitiesAdminPageState extends ConsumerState<CommunitiesAdminPage> {
  final _search = TextEditingController();
  List<Community>? _results;
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
      final res = await ref.read(apiClientProvider).raw.get('/communities', queryParameters: {
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      });
      setState(() {
        _results = (res.data as List)
            .map((e) => Community.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      setState(() => _error = AppException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Communities',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AC.ink900)),
                  SizedBox(height: 4),
                  Text('Onboard, configure, activate/deactivate, manage admins.',
                      style: TextStyle(fontSize: 14, color: AC.ink600)),
                ],
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New community'),
              onPressed: _openCreate,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search),
            hintText: 'Search communities by name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AC.red))
        else if (_results == null || _results!.isEmpty)
          const Text('No communities yet.')
        else
          Column(
            children: [
              for (final c in _results!)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.apartment),
                    title: Text(c.name),
                    subtitle: Text(c.address ?? c.status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CommunityDetailScreen(
                          communityId: c.id,
                          name: c.name,
                          address: c.address,
                          status: c.status,
                        ),
                      ));
                      _load();
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
