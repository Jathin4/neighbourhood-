import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../shared/community_content.dart';
import '../../shared/marketplace.dart';
import '../../shared/me.dart';
import '../../shared/my_memberships.dart';
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
    final openIssues = ref.watch(myIssuesProvider).maybeWhen(
          data: (list) => list.where((i) => i.status != 'resolved').length,
          orElse: () => 0,
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
    final membership = ref.watch(myActiveMembershipProvider);
    final activeBookings = ref.watch(myBookingsProvider).maybeWhen(
          data: (list) =>
              list.where((b) => b.status == 'requested' || b.status == 'accepted').length,
          orElse: () => 0,
        );

    return membership.when(
      loading: () => const _Loading(),
      error: (e, _) => Center(child: Text('$e')),
      data: (m) {
        if (m == null) {
          return ListView(
            padding: _bodyPad,
            children: [
              StatRow([
                const StatChip('0', 'Unread notices', highlight: true),
                const StatChip('0', 'Open issues'),
                const StatChip('0', 'Upcoming events'),
                StatChip('$activeBookings', 'Active bookings'),
              ]),
              const SizedBox(height: 16),
              const _Empty(
                  "You're not part of a community yet — a Community Admin needs to approve your membership."),
            ],
          );
        }

        final notices = ref.watch(noticesProvider(m.communityId));
        final events = ref.watch(eventsProvider(m.communityId));
        final issues = ref.watch(myIssuesProvider);
        final unreadNotices =
            notices.maybeWhen(data: (l) => l.where((n) => !n.read).length, orElse: () => 0);
        final openIssueCount = issues.maybeWhen(
            data: (l) => l.where((i) => i.status != 'resolved').length, orElse: () => 0);
        final eventCount = events.maybeWhen(data: (l) => l.length, orElse: () => 0);

        return ListView(
          padding: _bodyPad,
          children: [
            StatRow([
              StatChip('$unreadNotices', 'Unread notices', highlight: true),
              StatChip('$openIssueCount', 'Open issues'),
              StatChip('$eventCount', 'Upcoming events'),
              StatChip('$activeBookings', 'Active bookings'),
            ]),
            const SectionTitle('Notices'),
            notices.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) => list.isEmpty
                  ? const _Empty('No notices yet.')
                  : Column(children: [
                      for (final n in list.take(2)) _NoticeTile(communityId: m.communityId, notice: n),
                    ]),
            ),
            const SectionTitle('Open issues'),
            issues.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) {
                final open = list.where((i) => i.status != 'resolved').take(2).toList();
                return open.isEmpty
                    ? const _Empty('No open issues — nice and quiet.')
                    : Column(children: [for (final i in open) _IssueTile(i)]);
              },
            ),
            const SectionTitle('Upcoming events'),
            events.when(
              loading: () => const _Loading(),
              error: (e, _) => Text('$e'),
              data: (list) => list.isEmpty
                  ? const _Empty('No upcoming events.')
                  : Column(children: [
                      for (final e in list.take(2)) _EventTile(communityId: m.communityId, event: e),
                    ]),
            ),
          ],
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
}

class _NoticeTile extends ConsumerWidget {
  const _NoticeTile({required this.communityId, required this.notice});
  final String communityId;
  final CommunityNotice notice;

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(apiClientProvider)
          .raw
          .post('/communities/$communityId/notices/${notice.id}/read');
      ref.invalidate(noticesProvider(communityId));
      if (context.mounted) showSnack(context, 'Marked as read');
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final critical = notice.priority == 'critical';
    return TicketCard(
      cat: 'notice',
      status: critical ? TStatus.danger : TStatus.blue,
      id: fmtBookingWhen(notice.createdAt),
      title: notice.title,
      meta: [notice.body],
      trailing: Pill(critical ? 'Critical' : 'General', kind: critical ? PillKind.brick : PillKind.blue),
      actions: notice.read
          ? null
          : Row(children: [_outline('Mark as read', () => _markRead(context, ref))]),
    );
  }
}

// --- SERVICES --------------------------------------------------------

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab();

  Future<void> _request(BuildContext context, WidgetRef ref, ServiceCategory s) async {
    try {
      await ref.read(apiClientProvider).raw.post('/bookings', data: {
        'category': s.name,
        'title': s.name,
      });
      ref.invalidate(myBookingsProvider);
      if (context.mounted) showSnack(context, 'Request sent — providers will respond shortly');
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(residentProvider.select((d) => d.services));

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
                  onPressed: () => _request(context, ref, s),
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
    final bookings = ref.watch(myBookingsProvider);
    return ListView(
      padding: _bodyPad,
      children: [
        const Text('Track requests from booking to completion.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
        const SizedBox(height: 12),
        bookings.when(
          loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text('$e'),
          data: (list) => list.isEmpty
              ? const _Empty('No bookings yet — request a service from the Services tab.')
              : Column(children: [for (final b in list) _BookingTile(b)]),
        ),
      ],
    );
  }
}

class _BookingTile extends ConsumerWidget {
  const _BookingTile(this.booking);
  final MarketBooking booking;

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    try {
      await ref
          .read(apiClientProvider)
          .raw
          .patch('/bookings/${booking.id}', data: {'action': action});
      ref.invalidate(myBookingsProvider);
      if (context.mounted) {
        showSnack(context, action == 'cancel' ? 'Booking cancelled' : 'Updated');
      }
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, statusLabel) = bookingStatusInfo(booking.status);
    final pillKind = switch (status) {
      TStatus.success => PillKind.green,
      TStatus.amber => PillKind.amber,
      TStatus.danger => PillKind.brick,
      TStatus.blue => PillKind.blue,
    };
    final cancellable = booking.status == 'requested' || booking.status == 'accepted';

    return TicketCard(
      cat: marketCategoryIcon[booking.category] ?? 'build',
      status: status,
      id: booking.category,
      title: booking.title,
      meta: [
        booking.providerName ?? 'Matching a verified provider…',
        fmtBookingWhen(booking.createdAt),
      ],
      trailing: Pill(statusLabel, kind: pillKind),
      actions: cancellable
          ? Row(children: [
              _outline('Cancel', () => _act(context, ref, 'cancel')),
            ])
          : null,
    );
  }
}

// --- ISSUES -----------------------------------------------------------

class _IssuesTab extends ConsumerWidget {
  const _IssuesTab();

  Future<void> _raise(
      BuildContext context, WidgetRef ref, String communityId, String category, String title) async {
    try {
      await ref.read(apiClientProvider).raw.post('/issues', data: {
        'community_id': communityId,
        'category': category,
        'title': title.isEmpty ? 'Untitled issue' : title,
      });
      ref.invalidate(myIssuesProvider);
      if (context.mounted) showSnack(context, 'Issue submitted — a ticket has been created');
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(myActiveMembershipProvider);
    final issues = ref.watch(myIssuesProvider);

    return ListView(
      padding: _bodyPad,
      children: [
        membership.maybeWhen(
          data: (m) => m == null
              ? const SizedBox.shrink()
              : FilledButton(
                  onPressed: () => _showRaiseIssueSheet(context, ref, m.communityId),
                  style:
                      FilledButton.styleFrom(backgroundColor: PC.navy, minimumSize: const Size.fromHeight(44)),
                  child: const Text('Raise an issue'),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        issues.when(
          loading: () => const _Loading(),
          error: (e, _) => Text('$e'),
          data: (list) => list.isEmpty
              ? const _Empty('No issues raised yet.')
              : Column(children: [for (final i in list) _IssueTile(i, showReopen: true)]),
        ),
      ],
    );
  }

  void _showRaiseIssueSheet(BuildContext outerContext, WidgetRef ref, String communityId) {
    final title = TextEditingController();
    String category = 'Plumbing';
    showModalBottomSheet<void>(
      context: outerContext,
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
                  Navigator.pop(context);
                  _raise(outerContext, ref, communityId, category, title.text.trim());
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
  final CommunityIssue issue;
  final bool showReopen;

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(apiClientProvider).raw.patch('/issues/${issue.id}', data: {'action': 'reopen'});
      ref.invalidate(myIssuesProvider);
      if (context.mounted) showSnack(context, 'Issue reopened');
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      meta: ['Raised ${fmtBookingWhen(issue.createdAt)}'],
      trailing: Pill(statusLabel, kind: pillKind),
      actions: showReopen && issue.status == 'resolved'
          ? Row(children: [_outline('Reopen', () => _reopen(context, ref))])
          : null,
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.communityId, required this.event});
  final String communityId;
  final CommunityEvent event;

  Future<void> _toggleRsvp(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(apiClientProvider).raw.post('/communities/$communityId/events/${event.id}/rsvp');
      ref.invalidate(eventsProvider(communityId));
      if (context.mounted) {
        showSnack(context, event.rsvped ? 'RSVP cancelled' : 'RSVP confirmed');
      }
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, AppException.fromDio(e).message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TicketCard(
      cat: 'event',
      status: TStatus.blue,
      id: fmtBookingWhen(event.startsAt),
      title: event.title,
      meta: [event.location],
      trailing: event.rsvped ? const Pill('Going', kind: PillKind.green) : null,
      actions: Row(children: [
        _outline(event.rsvped ? 'Cancel RSVP' : 'RSVP', () => _toggleRsvp(context, ref)),
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
