import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import 'community_detail_screen.dart';
import 'panel_data.dart';
import 'quick_action_dialog.dart';

/// Community Management > Communities — real list + tap-through to configure/
/// activate-deactivate/manage-admins (§7 Communities module).
class CommunitiesAdminPage extends ConsumerWidget {
  const CommunitiesAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);

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
              onPressed: () => showQuickActionDialog(context, ref, 'Create Community'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        communities.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e', style: const TextStyle(color: AC.red)),
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
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CommunityDetailScreen(
                              communityId: c.id,
                              name: c.name,
                              address: c.address,
                              status: c.status,
                            ),
                          )),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
