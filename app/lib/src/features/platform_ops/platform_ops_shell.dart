import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/create_community_form.dart';
import '../../shared/role.dart';
import '../../shared/role_scaffold.dart' show GreetingHeader;
import '../../shared/ticket_ui.dart';
import '../auth/auth_controller.dart';
import 'platform_ops_home.dart';

/// Platform Operations as a real mobile app — tab bar matching the approved
/// prototype (Queue/Providers/Disputes/Reports/More), same pattern as the
/// Provider and Resident portals' shells.
class PlatformOpsShell extends StatefulWidget {
  const PlatformOpsShell({super.key});

  @override
  State<PlatformOpsShell> createState() => _PlatformOpsShellState();
}

class _PlatformOpsShellState extends State<PlatformOpsShell> {
  int _index = 0;
  static const _titles = ['Queue', 'Providers', 'Disputes', 'Reports', 'More'];

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
        children: const [_QueueTab(), _ProvidersTab(), _DisputesTab(), _ReportsTab(), _MoreTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(Icons.pending_actions),
              label: 'Queue'),
          NavigationDestination(
              icon: Icon(Icons.handyman_outlined),
              selectedIcon: Icon(Icons.handyman),
              label: 'Providers'),
          NavigationDestination(
              icon: Icon(Icons.gavel_outlined), selectedIcon: Icon(Icons.gavel), label: 'Disputes'),
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

class _QueueTab extends StatelessWidget {
  const _QueueTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: [
        const GreetingHeader(),
        const SizedBox(height: 16),
        const StatRow([
          StatChip('18', 'Providers pending review'),
          StatChip('5', 'Open disputes'),
        ]),
        const SectionTitle('Verification queue'),
        const InfoCard(
          title: 'Suresh Cooling Services',
          tag: 'Documents submitted',
          tagKind: PillKind.amber,
          desc: 'AC Technician · Hyderabad West zone.',
        ),
        const InfoCard(
          title: 'Report: Fake review flagged',
          tag: 'Needs action',
          tagKind: PillKind.brick,
          desc: 'Booking #TNN-B1042 · resident dispute.',
        ),
        const SectionTitle('Create community'),
        const CreateCommunityCard(),
        const SectionTitle('All communities'),
        const AllCommunitiesSection(),
      ],
    );
  }
}

class _ProvidersTab extends StatelessWidget {
  const _ProvidersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: const [
        SectionTitle('All providers'),
        InfoCard(
          title: 'Suresh Cooling Services',
          tag: 'Verified',
          tagKind: PillKind.green,
          desc: '4.8★ · 120 completed jobs.',
        ),
        InfoCard(
          title: 'Ramesh Plumbing',
          tag: 'Under review',
          tagKind: PillKind.amber,
          desc: 'Documents submitted 2 days ago.',
        ),
        InfoCard(
          title: 'QuickFix Electricians',
          tag: 'Suspended',
          tagKind: PillKind.brick,
          desc: '3 unresolved complaints.',
        ),
      ],
    );
  }
}

class _DisputesTab extends StatelessWidget {
  const _DisputesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: const [
        SectionTitle('Open cases'),
        InfoCard(
          title: '#TNN-B1042',
          tag: 'Needs action',
          tagKind: PillKind.brick,
          desc: 'Resident disputes review authenticity.',
        ),
        InfoCard(
          title: '#TNN-B0988',
          tag: 'Awaiting provider reply',
          tagKind: PillKind.amber,
          desc: 'Refund requested, 40% completed.',
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
        SectionTitle('Operations performance'),
        InfoCard(
          title: 'Provider approval time',
          tag: 'Avg 1.2 days',
          tagKind: PillKind.green,
          desc: 'Across last 30 days.',
        ),
        InfoCard(
          title: 'Dispute resolution',
          tag: 'Avg 3.4 days',
          tagKind: PillKind.amber,
          desc: '2 cases past SLA.',
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
