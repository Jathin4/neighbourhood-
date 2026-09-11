import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';
import 'communities.dart';

/// POST /communities — gated server-side to platform_ops/super_admin
/// (rbac.CAP_COMMUNITY_CREATE), so both of those homes can embed this.
class CreateCommunityCard extends ConsumerStatefulWidget {
  const CreateCommunityCard({super.key});

  @override
  ConsumerState<CreateCommunityCard> createState() => _CreateCommunityCardState();
}

class _CreateCommunityCardState extends ConsumerState<CreateCommunityCard> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).raw.post('/communities', data: {'name': name});
      _name.clear();
      ref.invalidate(communitiesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Community created')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppException.fromDio(e).message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create community', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Community name'),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: Text(_busy ? 'Creating...' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
