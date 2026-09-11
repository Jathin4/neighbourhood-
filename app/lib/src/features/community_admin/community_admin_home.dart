import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import '../../shared/role_scaffold.dart';
import 'pending_members_screen.dart';

class CommunityAdminHome extends ConsumerWidget {
  const CommunityAdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);

    return RoleScaffold(
      title: 'Community Admin',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(),
          const SizedBox(height: 16),
          Text('Communities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          communities.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Text(
                    'No communities yet — a Super Admin creates one and adds you as admin.')
                : Column(
                    children: [
                      for (final c in list)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.apartment),
                            title: Text(c.name),
                            subtitle: Text(c.address ?? c.status),
                            trailing: FilledButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PendingMembersScreen(
                                    communityId: c.id,
                                    communityName: c.name,
                                  ),
                                ),
                              ),
                              child: const Text('Pending'),
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
