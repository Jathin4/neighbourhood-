import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';

/// Platform Ops holds `community.create` server-side (rbac.py) — the real
/// list of every community that exists. Used by PlatformOpsShell's Queue tab.
class AllCommunitiesSection extends ConsumerWidget {
  const AllCommunitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);
    return communities.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (list) => list.isEmpty
          ? const Text('No communities yet.')
          : Column(
              children: [
                for (final c in list)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.apartment),
                      title: Text(c.name),
                      subtitle: Text(c.address ?? c.status),
                    ),
                  ),
              ],
            ),
    );
  }
}
