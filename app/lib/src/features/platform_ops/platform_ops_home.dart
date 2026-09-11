import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import '../../shared/create_community_form.dart';
import '../../shared/role_scaffold.dart';

/// Platform Ops holds `community.create` server-side (rbac.py) plus
/// verification/moderation/support scope (§7) — those modules aren't built
/// yet, so they're placeholders here.
class PlatformOpsHome extends ConsumerWidget {
  const PlatformOpsHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);

    return RoleScaffold(
      title: 'Platform Operations',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(),
          const SizedBox(height: 16),
          const CreateCommunityCard(),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.verified_user_outlined),
              title: Text('Provider verification'),
              subtitle: Text('Coming soon'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Content moderation'),
              subtitle: Text('Coming soon'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.support_agent_outlined),
              title: Text('Support tickets'),
              subtitle: Text('Coming soon'),
            ),
          ),
          const SizedBox(height: 8),
          Text('All communities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          communities.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Text('No communities yet.')
                : Column(
                    children: [
                      for (final c in list)
                        ListTile(
                          leading: const Icon(Icons.apartment),
                          title: Text(c.name),
                          subtitle: Text(c.address ?? c.status),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
