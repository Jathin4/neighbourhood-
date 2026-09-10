import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'data.dart';
import 'sub_screens.dart';
import 'ui.dart';

class ProviderShell extends ConsumerStatefulWidget {
  const ProviderShell({super.key});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Lead inbox',
    'Bookings',
    'Payouts',
    'More'
  ];
  static const _subs = [
    'Thu, 10 Sep — what needs attention',
    'New requests waiting for a response',
    'Your confirmed jobs',
    'Earnings & settlement history',
    'Profile, availability, reviews & support',
  ];

  @override
  Widget build(BuildContext context) {
    final leadCount = ref.watch(portalProvider.select((d) => d.leads.length));

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
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w600, color: PC.ink)),
            Text(_subs[_index],
                style: const TextStyle(fontSize: 11.5, color: PC.inkSoft)),
          ],
        ),
        actions: _index == 0
            ? [
                const Pill('✓ Verified', kind: PillKind.green),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: PC.navy,
                  child: Text('RK',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(width: 14),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _HomeTab(),
          _LeadsTab(),
          _BookingsTab(),
          _PayoutsTab(),
          _MoreTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
            icon: Badge.count(
              count: leadCount,
              isLabelVisible: leadCount > 0,
              child: const Icon(Icons.move_to_inbox_outlined),
            ),
            selectedIcon: Badge.count(
              count: leadCount,
              isLabelVisible: leadCount > 0,
              child: const Icon(Icons.move_to_inbox),
            ),
            label: 'Leads',
          ),
          const NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Bookings'),
          const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Payouts'),
          const NavigationDestination(
              icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

EdgeInsets get _bodyPad => const EdgeInsets.fromLTRB(16, 16, 16, 24);

// --- compact action buttons -------------------------------------------------

Widget _fill(String label, Color color, VoidCallback onTap,
        {Color fg = Colors.white}) =>
    Expanded(
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3))),
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
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
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3))),
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );

// --- HOME -----------------------------------------------------------------

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(portalProvider);
    final ctrl = ref.read(portalProvider.notifier);

    return ListView(
      padding: _bodyPad,
      children: [
        StatRow([
          StatChip('${data.leads.length}', 'New leads', highlight: true),
          const StatChip('2', 'Pending bookings'),
          const StatChip('4', 'Upcoming jobs'),
          const StatChip('₹18,400', 'Earned this month'),
          const StatChip('4.8★', 'Avg. rating'),
        ]),
        SectionTitle(
          'Needs your response',
          trailing: TextButton(
            onPressed: () {
              ctrl.resetLeads();
              showSnack(context, 'Demo leads restored');
            },
            child: const Text('Reset', style: TextStyle(fontSize: 11.5)),
          ),
        ),
        const Text('New leads expire after 30 minutes of inactivity.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
        const SizedBox(height: 12),
        if (data.leads.isEmpty)
          const _Empty('No new leads — new requests appear here.')
        else
          for (final l in data.leads.take(2)) _LeadTile(l),
        const SectionTitle('Today & tomorrow'),
        for (final b in data.bookings.take(2)) _BookingTile(b),
        PanelCard(
          title: 'Verification',
          child: const Text(
            'Identity & certificate verified 2 Jan 2026. Re-verification due in 118 days.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft, height: 1.6),
          ),
        ),
      ],
    );
  }
}

// --- LEADS ---------------------------------------------------------------

class _LeadsTab extends ConsumerWidget {
  const _LeadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(portalProvider.select((d) => d.leads));
    return ListView(
      padding: _bodyPad,
      children: [
        const Text('Accept, decline, or propose a different time or price.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
        const SizedBox(height: 12),
        if (leads.isEmpty)
          const _Empty('No new leads — new requests appear here.')
        else
          for (final l in leads) _LeadTile(l),
      ],
    );
  }
}

class _LeadTile extends ConsumerWidget {
  const _LeadTile(this.lead);
  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(portalProvider.notifier);
    return TicketCard(
      cat: lead.cat,
      status: TStatus.amber,
      id: lead.id,
      title: lead.title,
      meta: [
        lead.customer,
        '${lead.community} · ${lead.pref}',
        'Budget: ${lead.budget}'
      ],
      trailing: Pill(lead.mins, kind: PillKind.amber),
      actions: Row(
        children: [
          _fill('Accept', PC.navy, () {
            ctrl.acceptLead(lead.id);
            showSnack(context, 'Booking confirmed — resident notified');
          }),
          const SizedBox(width: 6),
          _outline('New time', () {
            showSnack(context, 'Alternate time sent to resident');
          }),
          const SizedBox(width: 6),
          _outline('Decline', () {
            ctrl.declineLead(lead.id);
            showSnack(context, 'Lead declined');
          }),
        ],
      ),
    );
  }
}

// --- BOOKINGS ----------------------------------------------------------

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(portalProvider.select((d) => d.bookings));
    return ListView(
      padding: _bodyPad,
      children: [
        const Text('Confirmed jobs across every community you serve.',
            style: TextStyle(fontSize: 11.5, color: PC.inkSoft)),
        const SizedBox(height: 12),
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
    final ctrl = ref.read(portalProvider.notifier);
    final pillKind = switch (booking.status) {
      TStatus.success => PillKind.green,
      TStatus.amber => PillKind.amber,
      _ => PillKind.blue,
    };
    return TicketCard(
      cat: booking.cat,
      status: booking.status,
      id: booking.id,
      title: booking.title,
      meta: [
        booking.customer,
        booking.community,
        '${booking.when} · ${booking.amount}',
      ],
      trailing: Pill(booking.statusLabel, kind: pillKind),
      actions: Row(
        children: [
          _outline('View details',
              () => showSnack(context, 'Opening ${booking.id}')),
          if (booking.status == TStatus.success) ...[
            const SizedBox(width: 6),
            _fill('Mark complete', PC.marigold, () {
              ctrl.completeJob(booking.id);
              showSnack(context, 'Job marked complete — resident will confirm');
            }, fg: const Color(0xFF28210A)),
          ],
        ],
      ),
    );
  }
}

// --- PAYOUTS ---------------------------------------------------------

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payouts = ref.watch(portalProvider.select((d) => d.payouts));
    return ListView(
      padding: _bodyPad,
      children: [
        StatRow(const [
          StatChip('₹18,400', 'Paid this month'),
          StatChip('₹2,150', 'Pending', highlight: true),
          StatChip('12%', 'Commission'),
          StatChip('Weekly', 'Payout cycle'),
        ]),
        const SizedBox(height: 12),
        PanelCard(
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(flex: 5, child: _Th('Job')),
                  Expanded(flex: 3, child: _Th('Gross')),
                  Expanded(flex: 3, child: _Th('Fee')),
                  Expanded(flex: 3, child: _Th('Net')),
                  Expanded(flex: 3, child: _Th('Status')),
                ],
              ),
              const Divider(height: 12, color: PC.line),
              for (final p in payouts) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.id,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ])),
                          Text(p.customer,
                              style: const TextStyle(
                                  fontSize: 9.5, color: PC.inkFaint)),
                        ],
                      ),
                    ),
                    Expanded(flex: 3, child: _Amt('₹${p.gross}')),
                    Expanded(
                        flex: 3, child: _Amt('−₹${p.fee}', color: PC.brick)),
                    Expanded(
                        flex: 3, child: _Amt('₹${p.net}', color: PC.green)),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Pill(p.status,
                            kind: p.status == 'Paid'
                                ? PillKind.green
                                : PillKind.amber),
                      ),
                    ),
                  ],
                ),
                if (p != payouts.last)
                  const Divider(height: 18, color: PC.lineSoft),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: PC.inkSoft,
          letterSpacing: 0.4));
}

class _Amt extends StatelessWidget {
  const _Amt(this.text, {this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color ?? PC.ink,
          fontFeatures: const [FontFeature.tabularFigures()]));
}

// --- MORE ----------------------------------------------------------

class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: _bodyPad,
      children: [
        _MenuRow(
          icon: Icons.person_outline,
          title: 'Profile & services',
          desc: 'Catalogue, pricing, team',
          onTap: () => _push(context, const ProfileScreen()),
        ),
        _MenuRow(
          icon: Icons.calendar_month_outlined,
          title: 'Availability',
          desc: 'Weekly hours & blackout dates',
          onTap: () => _push(context, const AvailabilityScreen()),
        ),
        _MenuRow(
          icon: Icons.star_outline,
          title: 'Reviews & reputation',
          desc: '4.8 average · 94 reviews',
          onTap: () => _push(context, const ReviewsScreen()),
        ),
        _MenuRow(
          icon: Icons.support_agent_outlined,
          title: 'Support & disputes',
          desc: 'Tickets & dispute history',
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
  const _MenuRow({
    required this.icon,
    required this.title,
    this.desc,
    required this.onTap,
  });

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
        decoration:
            BoxDecoration(color: PC.panel, border: Border.all(color: PC.line)),
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (desc != null)
                    Text(desc!,
                        style:
                            const TextStyle(fontSize: 10.5, color: PC.inkSoft)),
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
        decoration: BoxDecoration(
            border: Border.all(color: PC.line, style: BorderStyle.solid)),
        child: Center(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: PC.inkFaint)),
        ),
      );
}
