import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/me.dart';
import '../../shared/ticket_ui.dart';
import '../auth/auth_controller.dart';
import 'data.dart';
import 'sub_screens.dart';

/// Resident portal — same tab-bar shell/design system as the Service
/// Provider portal (shared/ticket_ui.dart), Resident content underneath
/// (requirements §2).
class ResidentShell extends ConsumerStatefulWidget {
  const ResidentShell({super.key});

  @override
  ConsumerState<ResidentShell> createState() => _ResidentShellState();
}

class _ResidentShellState extends ConsumerState<ResidentShell> {
  int _index = 0;

  static const _titles = ['Home', 'Services', 'Bookings', 'Issues', 'More'];
  static const _subs = [
    'Notices, issues and events at a glance',
    'Browse trusted providers near you',
    'Your service requests',
    'Raise and track complaints',
    'Profile, communities, notices & support',
  ];

  @override
  Widget build(BuildContext context) {
    final openIssues = ref.watch(
      residentProvider.select((d) => d.issues.where((i) => i.status != TStatus.success).length),
    );

    return Scaffold(
      backgroundColor: PC.bg,
      appBar: AppBar(
        backgroundColor: PC.panel,
        surfaceTintColor: PC.panel,
        titleSpacing: 18,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_titles[_index],
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: PC.ink)),
            Text(_subs[_index], style: const TextStyle(fontSize: 11.5, color: PC.inkSoft)),
          ],
        ),
        actions: _index == 0
            ? [
                Consumer(
                  builder: (context, ref, _) {
                    final me = ref.watch(meProvider);
                    final initials = me.maybeWhen(
                      data: (m) => (m.name ?? m.mobile).trim().isEmpty
                          ? '?'
                          : (m.name ?? m.mobile).trim()[0].toUpperCase(),
                      orElse: () => '…',
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: PC.navy,
                        child: Text(initials,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _index,
        children: const [_HomeTab(), _ServicesTab(), _BookingsTab(), _IssuesTab(), _MoreTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Services'),
          const NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Bookings'),
          NavigationDestination(
            icon: Badge.count(
              count: openIssues,
              isLabelVisible: openIssues > 0,
              child: const Icon(Icons.report_problem_outlined),
            ),
            selectedIcon: Badge.count(
              count: openIssues,
              isLabelVisible: openIssues > 0,
              child: const Icon(Icons.report_problem),
            ),
            label: 'Issues',
          ),
          const NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

EdgeInsets get _bodyPad => const EdgeInsets.fromLTRB(16, 16, 16, 24);

Widget _fill(String label, Color color, VoidCallback onTap, {Color fg = Colors.white}) => Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );

Widget _outline(String label, VoidCallback onTap) => Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: PC.ink,
          side: const BorderSide(color: PC.line),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );

// --- HOME -----------------------------------------------------------------

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(residentProvider);
    final ctrl = ref.read(residentProvider.notifier);
    final unreadNotices = data.notices.where((n) => !n.read).length;
    final openIssues = data.issues.where((i) => i.status != TStatus.success).length;

    return ListView(
      padding: _bodyPad,
      children: [
        StatRow([
          StatChip('$unreadNotices', 'Unread notices', highlight: true),
          StatChip('$openIssues', 'Open issues'),
          StatChip('${data.events.length}', 'Upcoming events'),
          StatChip('${data.bookings.length}', 'Active bookings'),
        ]),
        SectionTitle(
          'Notices',
          trailing: TextButton(
            onPressed: () {
              ctrl.resetDemo();
              showSnack(context, 'Demo data restored');
            },
            child: const Text('Reset', style: TextStyle(fontSize: 11.5)),
          ),
        ),
        for (final n in data.notices.take(2)) _NoticeTile(n),
        const SectionTitle('Open issues'),
        if (openIssues == 0)
          const _Empty('No open issues — nice and quiet.')
        else
          for (final i in data.issues.where((i) => i.status != TStatus.success).take(2))
            _IssueTile(i),
        const SectionTitle('Upcoming events'),
        for (final e in data.events.take(2)) _EventTile(e),
      ],
    );
  }
}

class _NoticeTile extends ConsumerWidget {
  const _NoticeTile(this.notice);
  final Notice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(residentProvider.notifier);
    return TicketCard(
      cat: 'notice',
      status: notice.priority == 'Critical' ? TStatus.danger : TStatus.blue,
      id: notice.date,
      title: notice.title,
      meta: [notice.body],
      trailing: Pill(notice.priority,
          kind: notice.priority == 'Critical' ? PillKind.brick : PillKind.blue),
      actions: notice.read
          ? null
          : Row(children: [
              _outline('Mark as read', () {
                ctrl.markNoticeRead(notice.id);
                showSnack(context, 'Marked as read');
              }),
            ]),
    );
  }
}

// --- SERVICES --------------------------------------------------------

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(residentProvider.select((d) => d.services));
    final ctrl = ref.read(residentProvider.notifier);

    return ListView(
      padding: _bodyPad,
      children: [
        const Text('Verified providers, ranked by rating, completed jobs and availability.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
        const SizedBox(height: 12),
        for (final s in services)
          PanelCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: PC.blueBg),
                  child: Icon(catIcon(s.cat), color: PC.navy, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(s.blurb, style: const TextStyle(fontSize: 11, color: PC.inkSoft)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    ctrl.requestService(s);
                    showSnack(context, 'Request sent — providers will respond shortly');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: PC.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape:
                        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
                  ),
                  child: const Text('Request', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --- BOOKINGS ----------------------------------------------------------

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(residentProvider.select((d) => d.bookings));
    return ListView(
      padding: _bodyPad,
      children: [
        const Text('Track requests from booking to completion.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          const _Empty('No bookings yet — request a service from the Services tab.')
        else
          for (final b in bookings) _BookingTile(b),
      ],
    );
  }
}

class _BookingTile extends ConsumerWidget {
  const _BookingTile(this.booking);
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(residentProvider.notifier);
    final pillKind = switch (booking.status) {
      TStatus.success => PillKind.green,
      TStatus.amber => PillKind.amber,
      TStatus.danger => PillKind.brick,
      TStatus.blue => PillKind.blue,
    };
    final awaitingConfirmation = booking.statusLabel == 'Awaiting confirmation';
    final cancellable = booking.statusLabel == 'Requested' || booking.statusLabel == 'Scheduled';

    return TicketCard(
      cat: booking.cat,
      status: booking.status,
      id: booking.id,
      title: booking.title,
      meta: [booking.provider, booking.community, '${booking.when} · ${booking.amount}'],
      trailing: Pill(booking.statusLabel, kind: pillKind),
      actions: Row(
        children: [
          _outline('View details', () => showSnack(context, 'Opening ${booking.id}')),
          if (awaitingConfirmation) ...[
            const SizedBox(width: 6),
            _fill('Confirm & rate', PC.marigold, () {
              ctrl.confirmCompletion(booking.id);
              showSnack(context, 'Thanks! Booking marked completed.');
            }, fg: const Color(0xFF28210A)),
          ] else if (cancellable) ...[
            const SizedBox(width: 6),
            _outline('Cancel', () {
              ctrl.cancelBooking(booking.id);
              showSnack(context, 'Booking cancelled');
            }),
          ],
        ],
      ),
    );
  }
}

// --- ISSUES -----------------------------------------------------------

class _IssuesTab extends ConsumerWidget {
  const _IssuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(residentProvider.select((d) => d.issues));
    final ctrl = ref.read(residentProvider.notifier);

    return ListView(
      padding: _bodyPad,
      children: [
        FilledButton(
          onPressed: () => _showRaiseIssueSheet(context, ctrl),
          style: FilledButton.styleFrom(backgroundColor: PC.navy, minimumSize: const Size.fromHeight(44)),
          child: const Text('Raise an issue'),
        ),
        const SizedBox(height: 16),
        for (final i in issues) _IssueTile(i, showReopen: true),
      ],
    );
  }

  void _showRaiseIssueSheet(BuildContext context, ResidentController ctrl) {
    final title = TextEditingController();
    String category = 'Plumbing';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Raise an issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  'Electrical', 'Plumbing', 'Cleanliness', 'Security', 'Common area', 'Other',
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => category = v ?? category),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'What\'s wrong?'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ctrl.raiseIssue(category, title.text.trim());
                  Navigator.pop(context);
                  showSnack(context, 'Issue submitted — a ticket has been created');
                },
                style: FilledButton.styleFrom(backgroundColor: PC.navy, minimumSize: const Size.fromHeight(44)),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueTile extends ConsumerWidget {
  const _IssueTile(this.issue, {this.showReopen = false});
  final IssueTicket issue;
  final bool showReopen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(residentProvider.notifier);
    final pillKind = switch (issue.status) {
      TStatus.success => PillKind.green,
      TStatus.amber => PillKind.amber,
      TStatus.danger => PillKind.brick,
      TStatus.blue => PillKind.blue,
    };
    return TicketCard(
      cat: issue.cat,
      status: issue.status,
      id: issue.id,
      title: issue.title,
      meta: ['Raised ${issue.date}'],
      trailing: Pill(issue.statusLabel, kind: pillKind),
      actions: showReopen && issue.status == TStatus.success
          ? Row(children: [
              _outline('Reopen', () {
                ctrl.reopenIssue(issue.id);
                showSnack(context, 'Issue reopened');
              }),
            ])
          : null,
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile(this.event);
  final EventItem event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(residentProvider.notifier);
    return TicketCard(
      cat: 'event',
      status: TStatus.blue,
      id: event.when,
      title: event.title,
      meta: [event.location],
      trailing: event.rsvped ? const Pill('Going', kind: PillKind.green) : null,
      actions: Row(children: [
        _outline(event.rsvped ? 'Cancel RSVP' : 'RSVP', () {
          ctrl.toggleRsvp(event.id);
          showSnack(context, event.rsvped ? 'RSVP cancelled' : 'RSVP confirmed');
        }),
      ]),
    );
  }
}

// --- MORE ---------------------------------------------------------

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: _bodyPad,
      children: [
        _MenuRow(
          icon: Icons.person_outline,
          title: 'Profile',
          desc: 'Your account details',
          onTap: () => _push(context, const ProfileTabScreen()),
        ),
        _MenuRow(
          icon: Icons.apartment_outlined,
          title: 'My communities',
          desc: 'Communities you belong to',
          onTap: () => _push(context, const MyCommunitiesScreen()),
        ),
        _MenuRow(
          icon: Icons.campaign_outlined,
          title: 'Notices',
          desc: 'All community announcements',
          onTap: () => _push(context, const AllNoticesScreen()),
        ),
        _MenuRow(
          icon: Icons.event_outlined,
          title: 'Events & polls',
          desc: 'Upcoming community events',
          onTap: () => _push(context, const AllEventsScreen()),
        ),
        _MenuRow(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          desc: 'Raise a platform support ticket',
          onTap: () => _push(context, const SupportScreen()),
        ),
        _MenuRow(
          icon: Icons.logout,
          title: 'Log out',
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
    );
  }

  static void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, this.desc, required this.onTap});

  final IconData icon;
  final String title;
  final String? desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: PC.panel, border: Border.all(color: PC.line)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: PC.blueBg,
              child: Icon(icon, size: 16, color: PC.navy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (desc != null) Text(desc!, style: const TextStyle(fontSize: 10.5, color: PC.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: PC.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(border: Border.all(color: PC.line)),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 12, color: PC.inkFaint))),
      );
}
