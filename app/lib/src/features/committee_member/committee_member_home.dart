import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/csv_import_screen.dart';
import '../../shared/members_management_screen.dart';
import '../../shared/my_memberships.dart';
import '../../shared/ticket_ui.dart';
import '../../shared/units_screen.dart';
import '../community_admin/community_issues_screen.dart';

/// Committee members get *configurable* per-membership capabilities (§1),
/// not a fixed role screen — what shows up here is driven entirely by which
/// capabilities the community admin actually granted, resolved server-side.
/// Used by CommitteeMemberShell's Tasks tab.
class CommitteeMembershipsSection extends ConsumerWidget {
  const CommitteeMembershipsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(myMembershipsProvider);
    return memberships.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (list) {
        final committee =
            list.where((m) => m.role == 'committee_member' && m.status == 'active').toList();
        if (committee.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Assigned operational workflows show up here once your community '
              'admin grants specific capabilities. Nothing assigned yet.',
              style: TextStyle(color: PC.inkSoft, fontSize: 12.5),
            ),
          );
        }
        return Column(children: [for (final m in committee) _CommitteeCard(m)]);
      },
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
                  if (membership.has('community.issue.manage'))
                    OutlinedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined, size: 16),
                      label: const Text('Issues'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CommunityIssuesScreen(
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
