import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/communities.dart';
import 'create_community_screen.dart';
import 'growth_chart.dart';
import 'panel_data.dart';
import 'quick_action_dialog.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);
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
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              label: 'Total Communities',
              value: communities.maybeWhen(data: (l) => '${l.length}', orElse: () => '—'),
              caption: 'Synced live from the database',
              icon: Icons.apartment_outlined,
              bg: AC.green50,
              fg: AC.green,
            ),
            for (final s in mockStats)
              _StatCard(
                label: s.label,
                value: s.value,
                delta: s.delta,
                up: s.up,
                icon: s.icon,
                bg: s.bg,
                fg: s.fg,
              ),
          ],
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
  const _Card({required this.child, this.title, this.trailing});
  final Widget child;
  final String? title;
  final Widget? trailing;

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
              child: Row(
                children: [
                  Expanded(
                    child: Text(title!,
                        style:
                            const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.fg,
    this.delta,
    this.up = true,
    this.caption,
  });

  final String label, value;
  final String? delta, caption;
  final bool up;
  final IconData icon;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
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
          if (delta != null)
            Row(
              children: [
                Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 13, color: up ? AC.green : AC.red),
                const SizedBox(width: 3),
                Text(delta!,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: up ? AC.green : AC.red)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'from last month',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AC.ink400),
                  ),
                ),
              ],
            )
          else if (caption != null)
            Text(caption!, style: const TextStyle(fontSize: 12, color: AC.ink400)),
        ],
      ),
    );
  }
}

class _PlatformGrowthCard extends StatelessWidget {
  const _PlatformGrowthCard();
  @override
  Widget build(BuildContext context) =>
      const _Card(title: 'Platform Growth', child: GrowthChart());
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

class _ApprovalsCard extends StatelessWidget {
  const _ApprovalsCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Pending Approvals',
      trailing: const Text('View All',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AC.blue)),
      child: Column(
        children: [
          for (final a in mockApprovals)
            InkWell(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${a.title.toLowerCase()} queue…')),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: a == mockApprovals.last
                    ? null
                    : const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AC.line))),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(color: a.bg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(a.icon, size: 17, color: a.fg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style:
                                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text(a.sub, style: const TextStyle(fontSize: 12, color: AC.ink600)),
                        ],
                      ),
                    ),
                    Text('${a.count}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Recent Activity',
      trailing: const Text('View All',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AC.blue)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 34,
          dataRowMinHeight: 46,
          dataRowMaxHeight: 46,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('TIME', style: TextStyle(fontSize: 11, color: AC.ink400))),
            DataColumn(label: Text('ACTION', style: TextStyle(fontSize: 11, color: AC.ink400))),
            DataColumn(label: Text('USER', style: TextStyle(fontSize: 11, color: AC.ink400))),
            DataColumn(label: Text('DETAILS', style: TextStyle(fontSize: 11, color: AC.ink400))),
          ],
          rows: [
            for (final a in mockActivity)
              DataRow(cells: [
                DataCell(Text(a.time, style: const TextStyle(fontSize: 13, color: AC.ink600))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration:
                        BoxDecoration(color: a.bg, borderRadius: BorderRadius.circular(6)),
                    child: Icon(a.icon, size: 12, color: a.color),
                  ),
                  const SizedBox(width: 8),
                  Text(a.action,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ])),
                DataCell(Text(a.user, style: const TextStyle(fontSize: 13, color: AC.ink600))),
                DataCell(Text(a.detail, style: const TextStyle(fontSize: 13, color: AC.ink600))),
              ]),
          ],
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
