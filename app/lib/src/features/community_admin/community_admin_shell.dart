import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/role.dart';
import '../../shared/role_scaffold.dart' show GreetingHeader;
import '../../shared/ticket_ui.dart';
import '../auth/auth_controller.dart';
import 'community_admin_home.dart';

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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: [
        const GreetingHeader(),
        const SizedBox(height: 16),
        const StatRow([
          StatChip('312', 'Active residents'),
          StatChip('7', 'Open issues'),
        ]),
        const SectionTitle('Needs your attention'),
        const InfoCard(
          title: 'Membership requests',
          tag: '4 pending',
          tagKind: PillKind.amber,
          desc: 'New residents from Tower D awaiting approval.',
        ),
        const InfoCard(
          title: 'AGM notice draft',
          tag: 'Unpublished',
          tagKind: PillKind.amber,
          desc: 'Scheduled for Sept 20 · targeting all residents.',
        ),
        const InfoCard(
          title: 'Curated providers',
          tag: '12 verified',
          tagKind: PillKind.green,
          desc: 'Suresh Cooling Services added this week.',
        ),
        const SectionTitle('Communities you administer'),
        const CommunityAdminMembershipsSection(),
      ],
    );
  }
}

class _ResidentsTab extends StatelessWidget {
  const _ResidentsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: const [
        SectionTitle('Directory'),
        InfoCard(
          title: 'Priya Raman',
          tag: 'Active',
          tagKind: PillKind.green,
          desc: 'B-304 · resident since 2023.',
        ),
        InfoCard(
          title: 'Rahul K.',
          tag: 'Active',
          tagKind: PillKind.green,
          desc: 'B-305 · resident since 2022.',
        ),
        InfoCard(
          title: 'Aditi S.',
          tag: 'Pending approval',
          tagKind: PillKind.amber,
          desc: 'D-102 · submitted request 2 days ago.',
        ),
      ],
    );
  }
}

class _NoticesTab extends StatelessWidget {
  const _NoticesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: const [
        SectionTitle('Published & drafts'),
        InfoCard(
          title: 'AGM Meeting',
          tag: 'Published',
          tagKind: PillKind.green,
          desc: 'Sept 20, 7pm · Clubhouse · all residents.',
        ),
        InfoCard(
          title: 'Water Supply Disruption',
          tag: 'Critical',
          tagKind: PillKind.brick,
          desc: 'Published to Tower B & C.',
        ),
        InfoCard(
          title: 'Diwali Community Event',
          tag: 'Draft',
          tagKind: PillKind.amber,
          desc: 'Not yet sent · targeting all residents.',
        ),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: const [
        SectionTitle('Community performance'),
        InfoCard(
          title: 'Issue resolution',
          tag: 'Avg 1.8 days',
          tagKind: PillKind.green,
          desc: 'Across all categories this month.',
        ),
        InfoCard(
          title: 'Notice read rate',
          tag: '82%',
          tagKind: PillKind.green,
          desc: 'Up 6pts from last month.',
        ),
        InfoCard(
          title: 'Provider satisfaction',
          tag: '4.6★',
          tagKind: PillKind.green,
          desc: 'Based on 58 completed bookings.',
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
