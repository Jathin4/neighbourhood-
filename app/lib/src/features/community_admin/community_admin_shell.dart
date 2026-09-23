import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/community_content.dart';
import '../../shared/my_memberships.dart';
import '../../shared/role.dart';
import '../../shared/members_management_screen.dart';
import '../../shared/role_scaffold.dart' show GreetingHeader;
import '../../shared/ticket_ui.dart';
import '../auth/auth_controller.dart';
import 'community_admin_home.dart';
import 'community_issues_screen.dart';

/// Community Admin as a real mobile app — tab bar matching the approved
/// prototype (Overview/Residents/Notices/Reports/More), same pattern as the
/// Provider and Resident portals' shells.
class CommunityAdminShell extends StatefulWidget {
  const CommunityAdminShell({super.key});

  @override
  State<CommunityAdminShell> createState() => _CommunityAdminShellState();
}

class _CommunityAdminShellState extends State<CommunityAdminShell> {
  int _index = 0;
  static const _titles = ['Overview', 'Residents', 'Notices', 'Reports', 'More'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PC.bg,
      appBar: AppBar(
        backgroundColor: PC.panel,
        surfaceTintColor: PC.panel,
        title: Text(_titles[_index],
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: PC.ink)),
      ),
      body: IndexedStack(
        index: _index,
        children: const [_OverviewTab(), _ResidentsTab(), _NoticesTab(), _ReportsTab(), _MoreTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Overview'),
          NavigationDestination(
              icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Residents'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Notices'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

const _bodyPad = EdgeInsets.fromLTRB(16, 16, 16, 24);

/// The admin's own community, resolved once and reused across the Overview,
/// Residents and Notices tabs (all scoped to the first community this
/// account actively administers).
final _adminMembershipProvider = firstActiveMembershipForRoleProvider('community_admin');

class _NoCommunity extends StatelessWidget {
  const _NoCommunity();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          "You're not an active admin of any community yet — a Super Admin creates one and assigns you.",
          style: TextStyle(color: PC.inkSoft, fontSize: 12.5),
        ),
      );
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(_adminMembershipProvider);
    return ListView(
      padding: _bodyPad,
      children: [
        const GreetingHeader(),
        const SizedBox(height: 16),
        membership.when(
          loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
          data: (m) => m == null
              ? const _NoCommunity()
              : _OverviewContent(communityId: m.communityId, communityName: m.communityName),
        ),
        const SectionTitle('Communities you administer'),
        const CommunityAdminMembershipsSection(),
      ],
    );
  }
}

class _OverviewContent extends ConsumerWidget {
  const _OverviewContent({required this.communityId, required this.communityName});
  final String communityId;
  final String communityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(communityMembersProvider(communityId));
    final issues = ref.watch(communityIssuesProvider(communityId));
    final active =
        members.maybeWhen(data: (l) => l.where((m) => m.status == 'active').length, orElse: () => 0);
    final pending =
        members.maybeWhen(data: (l) => l.where((m) => m.status == 'pending').length, orElse: () => 0);
    final openIssues = issues.maybeWhen(
        data: (l) => l.where((i) => i.status != 'resolved').length, orElse: () => 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatRow([
          StatChip('$active', 'Active residents'),
          StatChip('$openIssues', 'Open issues'),
        ]),
        const SectionTitle('Needs your attention'),
        if (pending > 0)
          InfoCard(
            title: 'Membership requests',
            tag: '$pending pending',
            tagKind: PillKind.amber,
            desc: 'New residents awaiting approval in $communityName.',
          )
        else
          const Text('No pending membership requests.',
              style: TextStyle(color: PC.inkSoft, fontSize: 12.5)),
      ],
    );
  }
}

class _ResidentsTab extends ConsumerWidget {
  const _ResidentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(_adminMembershipProvider);
    return membership.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (m) {
        if (m == null) {
          return ListView(padding: _bodyPad, children: const [_NoCommunity()]);
        }
        final members = ref.watch(communityMembersProvider(m.communityId));
        return ListView(
          padding: _bodyPad,
          children: [
            const SectionTitle('Directory'),
            members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (list) => list.isEmpty
                  ? const Text('No residents yet.', style: TextStyle(color: PC.inkSoft, fontSize: 12.5))
                  : Column(children: [
                      for (final mem in list)
                        InfoCard(
                          title: mem.role.replaceAll('_', ' '),
                          tag: mem.status,
                          tagKind: switch (mem.status) {
                            'active' => PillKind.green,
                            'pending' => PillKind.amber,
                            _ => PillKind.brick,
                          },
                          desc: 'Membership ${mem.id.substring(0, 8)}',
                        ),
                    ]),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    MembersManagementScreen(communityId: m.communityId, communityName: m.communityName),
              )),
              style: FilledButton.styleFrom(backgroundColor: PC.navy, minimumSize: const Size.fromHeight(44)),
              child: const Text('Manage residents'),
            ),
          ],
        );
      },
    );
  }
}

class _NoticesTab extends ConsumerWidget {
  const _NoticesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(_adminMembershipProvider);
    return membership.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (m) => m == null
          ? ListView(padding: _bodyPad, children: const [_NoCommunity()])
          : _NoticesContent(communityId: m.communityId),
    );
  }
}

class _NoticesContent extends ConsumerWidget {
  const _NoticesContent({required this.communityId});
  final String communityId;

  Future<void> _create(BuildContext outerContext, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String priority = 'general';
    final ok = await showModalBottomSheet<bool>(
      context: outerContext,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (sheetContext, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New notice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical')),
                ],
                onChanged: (v) => setState(() => priority = v ?? priority),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                style: FilledButton.styleFrom(backgroundColor: PC.navy, minimumSize: const Size.fromHeight(44)),
                child: const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !outerContext.mounted) return;
    try {
      await ref.read(apiClientProvider).raw.post('/communities/$communityId/notices', data: {
        'title': titleCtrl.text.trim().isEmpty ? 'Untitled' : titleCtrl.text.trim(),
        'body': bodyCtrl.text.trim(),
        'priority': priority,
      });
      ref.invalidate(noticesProvider(communityId));
      if (outerContext.mounted) showSnack(outerContext, 'Notice published');
    } on DioException catch (e) {
      if (outerContext.mounted) showSnack(outerContext, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider(communityId));
    return ListView(
      padding: _bodyPad,
      children: [
        FilledButton.icon(
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New notice'),
          style: FilledButton.styleFrom(backgroundColor: PC.navy, minimumSize: const Size.fromHeight(44)),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Published'),
        notices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (list) => list.isEmpty
              ? const Text('No notices published yet.', style: TextStyle(color: PC.inkSoft, fontSize: 12.5))
              : Column(children: [
                  for (final n in list)
                    InfoCard(
                      title: n.title,
                      tag: n.priority == 'critical' ? 'Critical' : 'Published',
                      tagKind: n.priority == 'critical' ? PillKind.brick : PillKind.green,
                      desc: n.body,
                    ),
                ]),
        ),
      ],
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(_adminMembershipProvider);
    return membership.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (m) => m == null
          ? ListView(padding: _bodyPad, children: const [_NoCommunity()])
          : _ReportsContent(communityId: m.communityId),
    );
  }
}

class _ReportsContent extends ConsumerWidget {
  const _ReportsContent({required this.communityId});
  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider(communityId));
    final events = ref.watch(eventsProvider(communityId));
    final issues = ref.watch(communityIssuesProvider(communityId));

    final noticeCount = notices.maybeWhen(data: (l) => l.length, orElse: () => 0);
    final eventCount = events.maybeWhen(data: (l) => l.length, orElse: () => 0);
    final resolved =
        issues.maybeWhen(data: (l) => l.where((i) => i.status == 'resolved').length, orElse: () => 0);
    final totalIssues = issues.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return ListView(
      padding: _bodyPad,
      children: [
        const SectionTitle('Community activity'),
        InfoCard(
          title: 'Issues resolved',
          tag: '$resolved / $totalIssues',
          tagKind: totalIssues == 0 || resolved == totalIssues ? PillKind.green : PillKind.amber,
          desc: 'Resolved vs. total issues raised in this community.',
        ),
        InfoCard(
          title: 'Notices published',
          tag: '$noticeCount',
          tagKind: PillKind.blue,
          desc: 'Total notices sent to residents.',
        ),
        InfoCard(
          title: 'Events scheduled',
          tag: '$eventCount',
          tagKind: PillKind.blue,
          desc: 'Total events created for this community.',
        ),
      ],
    );
  }
}

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: _bodyPad,
      children: [
        Builder(builder: (context) {
          final membership = ref.watch(_adminMembershipProvider);
          final m = membership.maybeWhen(data: (m) => m, orElse: () => null);
          if (m == null) return const SizedBox.shrink();
          return MenuRow(
            icon: Icons.report_problem_outlined,
            title: 'Issues',
            desc: 'Resolve issues raised in ${m.communityName}',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  CommunityIssuesScreen(communityId: m.communityId, communityName: m.communityName),
            )),
          );
        }),
        MenuRow(
          icon: Icons.switch_account_outlined,
          title: 'Switch role',
          desc: 'View the app as a different role',
          onTap: () {
            ref.read(roleProvider.notifier).state = null;
            context.go('/role');
          },
        ),
        MenuRow(
          icon: Icons.logout,
          title: 'Log out',
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
    );
  }
}
