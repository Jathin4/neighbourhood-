import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/community_detail_screen.dart';
import '../../shared/csv_import_screen.dart';
import '../../shared/my_memberships.dart';
import '../../shared/role_scaffold.dart';
import '../../shared/units_screen.dart';

/// §6 Community Administration: configure community/units, bulk resident
/// import, approve/reject membership, assign admin/committee permissions —
/// scoped to whichever communities this user is actually an active admin of.
class CommunityAdminHome extends ConsumerWidget {
  const CommunityAdminHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider);

    return RoleScaffold(
      title: 'Community Admin',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(),
          const SizedBox(height: 16),
          Text('Communities you administer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          memberships.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) {
              final admin = list
                  .where((m) => m.role == 'community_admin' && m.status == 'active')
                  .toList();
              if (admin.isEmpty) {
                return const Text(
                    'You are not an active admin of any community yet — a Super Admin '
                    'creates one and assigns you.');
              }
              return Column(
                children: [for (final m in admin) _CommunityAdminCard(m)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityAdminCard extends StatelessWidget {
  const _CommunityAdminCard(this.membership);
  final MyMembership membership;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.apartment),
              const SizedBox(width: 10),
              Expanded(
                child: Text(membership.communityName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Manage'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CommunityDetailScreen(
                      communityId: membership.communityId,
                      name: membership.communityName,
                    ),
                  )),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.apartment_outlined, size: 16),
                  label: const Text('Units'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UnitsScreen(
                      communityId: membership.communityId,
                      communityName: membership.communityName,
                    ),
                  )),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Import CSV'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CsvImportScreen(
                      communityId: membership.communityId,
                      communityName: membership.communityName,
                    ),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
