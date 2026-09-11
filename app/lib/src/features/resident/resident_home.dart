import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import '../../shared/role_scaffold.dart';

/// Home dashboard shell (requirements §2.2). Notices/issues/events sections
/// are placeholders until those backend modules ship (see requirements §19).
class ResidentHome extends ConsumerWidget {
  const ResidentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);

    return RoleScaffold(
      title: 'Resident',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(),
          const SizedBox(height: 16),
          const _Section(icon: Icons.campaign, title: 'Notices', body: 'No notices yet.'),
          const _Section(
              icon: Icons.report_problem, title: 'Open issues', body: 'Nothing open.'),
          const _Section(
              icon: Icons.event, title: 'Upcoming events', body: 'Nothing scheduled.'),
          const SizedBox(height: 8),
          Text('My communities', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          communities.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Text('Not part of any community yet.')
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
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
