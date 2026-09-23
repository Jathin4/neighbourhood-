import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/community_content.dart';
import '../../shared/marketplace.dart' show fmtBookingWhen;
import '../../shared/ticket_ui.dart';

/// The issue queue for a community, resolvable by whoever holds
/// community.issue.manage there (Community Admin, or a Committee Member
/// granted that capability).
class CommunityIssuesScreen extends ConsumerWidget {
  const CommunityIssuesScreen({required this.communityId, required this.communityName, super.key});

  final String communityId;
  final String communityName;

  Future<void> _act(BuildContext context, WidgetRef ref, String issueId, String action) async {
    try {
      await ref.read(apiClientProvider).raw.patch('/issues/$issueId', data: {'action': action});
      ref.invalidate(communityIssuesProvider(communityId));
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(communityIssuesProvider(communityId));
    return Scaffold(
      backgroundColor: PC.bg,
      appBar: AppBar(
        backgroundColor: PC.panel,
        surfaceTintColor: PC.panel,
        title: Text('Issues — $communityName',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: PC.ink)),
      ),
      body: issues.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No issues raised yet.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final i in list)
                    _IssueRow(issue: i, onAct: (action) => _act(context, ref, i.id, action)),
                ],
              ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  const _IssueRow({required this.issue, required this.onAct});
  final CommunityIssue issue;
  final void Function(String action) onAct;

  @override
  Widget build(BuildContext context) {
    final (status, statusLabel) = issueStatusInfo(issue.status);
    final pillKind = switch (status) {
      TStatus.success => PillKind.green,
      TStatus.amber => PillKind.amber,
      TStatus.danger => PillKind.brick,
      TStatus.blue => PillKind.blue,
    };
    return TicketCard(
      cat: 'issue',
      status: status,
      id: issue.category,
      title: issue.title,
      meta: ['Raised by ${issue.raisedByName}', fmtBookingWhen(issue.createdAt)],
      trailing: Pill(statusLabel, kind: pillKind),
      actions: issue.status == 'submitted' || issue.status == 'reopened'
          ? Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAct('start'),
                  style: OutlinedButton.styleFrom(foregroundColor: PC.ink, side: const BorderSide(color: PC.line)),
                  child: const Text('Start', style: TextStyle(fontSize: 11.5)),
                ),
              ),
            ])
          : issue.status == 'in_progress'
              ? Row(children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onAct('resolve'),
                      style: FilledButton.styleFrom(backgroundColor: PC.navy),
                      child: const Text('Resolve', style: TextStyle(fontSize: 11.5)),
                    ),
                  ),
                ])
              : null,
    );
  }
}
