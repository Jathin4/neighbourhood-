import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import '../../shared/create_community_form.dart';
import '../../shared/role_scaffold.dart';

class SuperAdminHome extends ConsumerWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);

    return RoleScaffold(
      title: 'Super Admin',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(),
          const SizedBox(height: 16),
          const CreateCommunityCard(),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.rule_folder_outlined),
              title: Text('RBAC & configuration'),
              subtitle: Text('Coming soon'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Finance & audit'),
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
