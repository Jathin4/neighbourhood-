import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/csv_import_screen.dart';
import '../../shared/members_management_screen.dart';
import '../../shared/my_memberships.dart';
import '../../shared/role_scaffold.dart';
import '../../shared/ticket_ui.dart';
import '../../shared/units_screen.dart';

/// Committee members get *configurable* per-membership capabilities (§1),
/// not a fixed role screen — what shows up here is driven entirely by which
/// capabilities the community admin actually granted, resolved server-side.
class CommitteeMemberHome extends ConsumerWidget {
  const CommitteeMemberHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider);

    return RoleScaffold(
      title: 'Committee Member',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GreetingHeader(),
          const SizedBox(height: 16),
          memberships.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (list) {
              final committee = list
                  .where((m) => m.role == 'committee_member' && m.status == 'active')
                  .toList();
              if (committee.isEmpty) {
                return const _CommitteeMemberDemo();
              }
              return Column(children: [for (final m in committee) _CommitteeCard(m)]);
            },
          ),
        ],
      ),
    );
  }
}

/// Shown when this account has no active committee_member membership yet —
/// sample content so the screen doesn't read as blank, using the same
/// community/tasks pattern as the demo assignments a community admin would
/// actually grant (§1: unit manage, member manage, resident import).
class _CommitteeMemberDemo extends StatelessWidget {
  const _CommitteeMemberDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nothing assigned yet — here's a demo preview of the kind of workflows "
          'a community admin can grant you (unit management, member approvals, '
          'resident import).',
          style: TextStyle(color: PC.inkSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        PanelCard(
          title: 'Green Meadows Residency (demo)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              TicketCard(
                cat: 'directory',
                status: TStatus.amber,
                id: 'TASK-1',
                title: 'Verify new resident registrations',
                meta: ['4 pending approvals'],
              ),
              TicketCard(
                cat: 'directory',
                status: TStatus.blue,
                id: 'TASK-2',
                title: 'Update flat directory — Tower B',
                meta: ['Unit management capability'],
              ),
              TicketCard(
                cat: 'issue',
                status: TStatus.success,
                id: 'TASK-3',
                title: 'Review flagged notices',
                meta: ['Resolved earlier this week'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommitteeCard extends StatelessWidget {
  const _CommitteeCard(this.membership);
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
            if (membership.capabilities.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No capabilities granted yet — ask your community admin.',
                    style: TextStyle(color: Colors.grey, fontSize: 12.5)),
              )
            else ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (membership.has('community.member.manage'))
                    OutlinedButton.icon(
                      icon: const Icon(Icons.groups_outlined, size: 16),
                      label: const Text('Manage members'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MembersManagementScreen(
                          communityId: membership.communityId,
                          communityName: membership.communityName,
                        ),
                      )),
                    ),
                  if (membership.has('community.unit.manage'))
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
                  if (membership.has('community.resident.import'))
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
          ],
        ),
      ),
    );
  }
}
