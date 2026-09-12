import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/role.dart';
import '../../shared/role_scaffold.dart' show GreetingHeader;
import '../../shared/ticket_ui.dart';
import '../auth/auth_controller.dart';
import 'committee_member_home.dart';

/// Committee Member as a real mobile app — tab bar matching the approved
/// prototype (Tasks/Polls/Notices/More), same pattern as the Provider and
/// Resident portals' shells.
class CommitteeMemberShell extends StatefulWidget {
  const CommitteeMemberShell({super.key});

  @override
  State<CommitteeMemberShell> createState() => _CommitteeMemberShellState();
}

class _CommitteeMemberShellState extends State<CommitteeMemberShell> {
  int _index = 0;
  static const _titles = ['Tasks', 'Polls', 'Notices', 'More'];

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
        children: const [_TasksTab(), _PollsTab(), _NoticesTab(), _MoreTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.poll_outlined), selectedIcon: Icon(Icons.poll), label: 'Polls'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

const _bodyPad = EdgeInsets.fromLTRB(16, 16, 16, 24);

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: [
        const GreetingHeader(),
        const SizedBox(height: 16),
        const SectionTitle('Your assigned workflows'),
        const InfoCard(
          title: 'Clubhouse booking approvals',
          tag: '3 pending',
          tagKind: PillKind.amber,
          desc: 'Weekend event requests awaiting sign-off.',
        ),
        const InfoCard(
          title: 'Landscaping vendor review',
          tag: 'Completed',
          tagKind: PillKind.green,
          desc: 'Quarterly quality check submitted.',
        ),
        const InfoCard(
          title: 'Poll: Solar panel installation',
          tag: 'Open · 2 days left',
          tagKind: PillKind.amber,
          desc: '64% turnout so far.',
        ),
        const SectionTitle('Granted by your community admin'),
        const CommitteeMembershipsSection(),
      ],
    );
  }
}

class _PollsTab extends StatelessWidget {
  const _PollsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _bodyPad,
      children: const [
        SectionTitle('Active & past polls'),
        InfoCard(
          title: 'Solar panel installation',
          tag: '64% turnout',
          tagKind: PillKind.amber,
          desc: 'Closes in 2 days · anonymous.',
        ),
        InfoCard(
          title: 'New gym equipment',
          tag: 'Passed',
          tagKind: PillKind.green,
          desc: '78% in favour · closed last month.',
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
        SectionTitle('Community notices'),
        InfoCard(
          title: 'AGM Meeting',
          tag: 'Published',
          tagKind: PillKind.green,
          desc: 'Sept 20, 7pm · Clubhouse.',
        ),
        InfoCard(
          title: 'Water Supply Disruption',
          tag: 'Critical',
          tagKind: PillKind.brick,
          desc: 'Tower B & C.',
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
