import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/community_detail_screen.dart';
import '../../shared/csv_import_screen.dart';
import '../../shared/my_memberships.dart';
import '../../shared/ticket_ui.dart';
import '../../shared/units_screen.dart';

/// §6 Community Administration: configure community/units, bulk resident
/// import, approve/reject membership, assign admin/committee permissions —
/// scoped to whichever communities this user is actually an active admin of.
/// Used by CommunityAdminShell's Overview tab.
class CommunityAdminMembershipsSection extends ConsumerWidget {
  const CommunityAdminMembershipsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider);
    return memberships.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (list) {
        final admin =
            list.where((m) => m.role == 'community_admin' && m.status == 'active').toList();
        if (admin.isEmpty) {
          return const _CommunityAdminDemo();
        }
        return Column(
          children: [for (final m in admin) _CommunityAdminCard(m)],
        );
      },
    );
  }
}

/// Shown when this account isn't an active admin of any real community yet
/// (a Super Admin has to create one and assign it) — sample content so the
/// screen doesn't read as broken, using the same community/notices as the
/// Resident portal's own mock data so it feels like one connected demo.
class _CommunityAdminDemo extends StatelessWidget {
  const _CommunityAdminDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "You're not an active admin of any real community yet — here's a demo "
          "preview of what you'll manage once a Super Admin assigns you one.",
          style: TextStyle(color: PC.inkSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        PanelCard(
          title: 'Green Meadows Residency (demo)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatRow([
                StatChip('428', 'Residents'),
                StatChip('3', 'Open notices'),
                StatChip('2', 'Open issues'),
                StatChip('3', 'Upcoming events'),
              ]),
              const SectionTitle('Recent notices'),
              const TicketCard(
                cat: 'notice',
                status: TStatus.danger,
                id: 'NOT-501',
                title: 'Water supply interruption — 12 Sep, 10 AM–2 PM',
                meta: ['Maintenance work on the main line', 'Today'],
              ),
              const TicketCard(
                cat: 'notice',
                status: TStatus.blue,
                id: 'NOT-498',
                title: 'Diwali cultural night — sign up for stalls',
                meta: ['Community hall, 7 PM onwards', 'Yesterday'],
              ),
              const SectionTitle('Open issues'),
              const TicketCard(
                cat: 'issue',
                status: TStatus.amber,
                id: 'ISS-1042',
                title: 'Lift in B-Block making a grinding noise',
                meta: ['Reported by a resident', '2 days ago'],
              ),
            ],
          ),
        ),
      ],
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
