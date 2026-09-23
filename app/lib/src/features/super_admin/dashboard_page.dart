import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import 'create_community_screen.dart';
import 'dashboard_data.dart';
import 'growth_chart.dart';
import 'panel_data.dart';
import 'quick_action_dialog.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final wide = MediaQuery.of(context).size.width > 900;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 12,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AC.ink900)),
                SizedBox(height: 4),
                Text('Platform overview and key metrics',
                    style: TextStyle(fontSize: 14, color: AC.ink600)),
              ],
            ),
            _DateRangeChip(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Date range picker would open here.')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 16.0;
            final columns = (constraints.maxWidth / 230).floor().clamp(2, 4);
            final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _StatCard(
                  width: cardWidth,
                  label: 'Total Communities',
                  value: communities.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
                  caption: 'Synced live from the database',
                  icon: Icons.apartment_outlined,
                  bg: AC.green50,
                  fg: AC.green,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Total Residents',
                  value: stats.maybeWhen(data: (s) => '${s.totalResidents}', orElse: () => '—'),
                  caption: 'Active resident memberships',
                  icon: Icons.groups_outlined,
                  bg: AC.blue50,
                  fg: AC.blue,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Community Admins',
                  value: stats.maybeWhen(data: (s) => '${s.communityAdmins}', orElse: () => '—'),
                  caption: 'Active across all communities',
                  icon: Icons.shield_outlined,
                  bg: AC.purple50,
                  fg: AC.purple,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Committee Members',
                  value: stats.maybeWhen(data: (s) => '${s.committeeMembers}', orElse: () => '—'),
                  caption: 'Active across all communities',
                  icon: Icons.diversity_3_outlined,
                  bg: AC.amber50,
                  fg: AC.amber,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Service Providers',
                  value: stats.maybeWhen(data: (s) => '${s.serviceProviders}', orElse: () => '—'),
                  caption: 'Registered provider profiles',
                  icon: Icons.handyman_outlined,
                  bg: AC.teal50,
                  fg: AC.teal,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Total Bookings',
                  value: stats.maybeWhen(data: (s) => '${s.totalBookings}', orElse: () => '—'),
                  caption: 'All bookings, any status',
                  icon: Icons.calendar_month_outlined,
                  bg: AC.red50,
                  fg: AC.red,
                ),
                _StatCard(
                  width: cardWidth,
                  label: 'Pending Membership Approvals',
                  value: stats.maybeWhen(
                      data: (s) => '${s.pendingMembershipApprovals}', orElse: () => '—'),
                  caption: 'Across every community',
                  icon: Icons.pending_actions_outlined,
                  bg: AC.amber50,
                  fg: AC.amber,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 21, child: _PlatformGrowthCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 10, child: _QuickActionsCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 10, child: _ApprovalsCard()),
                  ],
                ),
              )
            : Column(
                children: [
                  const _PlatformGrowthCard(),
                  const SizedBox(height: 16),
                  const _QuickActionsCard(),
                  const SizedBox(height: 16),
                  const _ApprovalsCard(),
                ],
              ),
        const SizedBox(height: 16),
        wide
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _ActivityCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _HealthCard()),
                  ],
                ),
              )
            : Column(children: const [_ActivityCard(), SizedBox(height: 16), _HealthCard()]),
      ],
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AC.surface,
          border: Border.all(color: AC.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: AC.ink600),
            SizedBox(width: 8),
            Text('Apr 27, 2025 – May 27, 2025',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            SizedBox(width: 6),
            Icon(Icons.expand_more, size: 16, color: AC.ink400),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.title});
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AC.surface,
        border: Border.all(color: AC.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(title!, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
            ),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
    this.caption,
  });

  final double width;
  final String label, value;
  final String? caption;
  final IconData icon;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AC.surface,
        border: Border.all(color: AC.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AC.ink600)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AC.ink900)),
          const SizedBox(height: 6),
          if (caption != null)
            Text(caption!, style: const TextStyle(fontSize: 12, color: AC.ink400)),
        ],
      ),
    );
  }
}

class _PlatformGrowthCard extends ConsumerWidget {
  const _PlatformGrowthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growth = ref.watch(growthSeriesProvider);
    return _Card(
      title: 'Platform Growth (last 10 days)',
      child: growth.when(
        loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(height: 240, child: Center(child: Text('$e'))),
        data: (g) => GrowthChart(
          labels: g.labels,
          series: {
            'New Users': g.newUsers.map((v) => v.toDouble()).toList(),
            'New Bookings': g.newBookings.map((v) => v.toDouble()).toList(),
          },
          colors: const {'New Users': AC.blue, 'New Bookings': AC.green},
        ),
      ),
    );
  }
}

class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: 'Quick Actions',
      child: Column(
        children: [
          for (final q in quickActions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => q.label == 'Create Community'
                    ? Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const CreateCommunityScreen()))
                    : showQuickActionDialog(context, q.label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AC.line),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(color: q.bg, borderRadius: BorderRadius.circular(9)),
                        child: Icon(q.icon, size: 17, color: q.fg),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(q.label,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AC.ink400),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApprovalsCard extends ConsumerWidget {
  const _ApprovalsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return _Card(
      title: 'Pending Approvals',
      child: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (s) => Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AC.green50, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.groups_outlined, size: 17, color: AC.green),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Membership Approvals',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Text('Pending across every community',
                      style: TextStyle(fontSize: 12, color: AC.ink600)),
                ],
              ),
            ),
            Text('${s.pendingMembershipApprovals}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

IconData _activityIcon(String action) => switch (action) {
      'community.create' => Icons.apartment,
      'community.update' => Icons.edit_outlined,
      'community.member.update' => Icons.person_outline,
      'community.resident.import' => Icons.upload_file,
      'user.status_update' => Icons.block,
      _ => Icons.bolt_outlined,
    };

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    return _Card(
      title: 'Recent Activity',
      child: activity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (list) => list.isEmpty
            ? const Text('No activity yet.', style: TextStyle(color: AC.ink600))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 34,
                  dataRowMinHeight: 46,
                  dataRowMaxHeight: 46,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('TIME', style: TextStyle(fontSize: 11, color: AC.ink400))),
                    DataColumn(
                        label: Text('ACTION', style: TextStyle(fontSize: 11, color: AC.ink400))),
                    DataColumn(label: Text('USER', style: TextStyle(fontSize: 11, color: AC.ink400))),
                    DataColumn(
                        label: Text('DETAILS', style: TextStyle(fontSize: 11, color: AC.ink400))),
                  ],
                  rows: [
                    for (final a in list)
                      DataRow(cells: [
                        DataCell(Text(
                            '${a.createdAt.hour.toString().padLeft(2, '0')}:'
                            '${a.createdAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 13, color: AC.ink600))),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration:
                                BoxDecoration(color: AC.blue50, borderRadius: BorderRadius.circular(6)),
                            child: Icon(_activityIcon(a.action), size: 12, color: AC.blue),
                          ),
                          const SizedBox(width: 8),
                          Text(a.action,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ])),
                        DataCell(Text(a.actorMobile ?? '—',
                            style: const TextStyle(fontSize: 13, color: AC.ink600))),
                        DataCell(Text(
                            a.entityId != null ? '${a.entity} · ${a.entityId!.substring(0, 8)}' : a.entity,
                            style: const TextStyle(fontSize: 13, color: AC.ink600))),
                      ]),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'System Health',
      child: Column(
        children: [
          for (final h in healthItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: AC.blue50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(h.$2, size: 15, color: AC.ink600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(h.$1,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: AC.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Healthy',
                      style:
                          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AC.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
