import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/role.dart';
import '../auth/auth_controller.dart';
import 'audit_logs_page.dart';
import 'communities_admin_page.dart';
import 'dashboard_page.dart';
import 'panel_data.dart';
import 'users_page.dart';

/// Nav leaves with a real page behind them; everything else in navItems
/// still renders the prototype's own placeholder.
final _realPages = <String, Widget Function()>{
  'Communities': CommunitiesAdminPage.new,
  'All Users': UsersPage.new,
  'Audit Logs': AuditLogsPage.new,
};

/// Super Admin Panel shell: navy sidebar + topbar + content, matching the
/// approved prototype. Only Dashboard has real content; every other nav leaf
/// is a placeholder — that's what the prototype itself does too.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _selected = 'Dashboard';
  bool _collapsed = false;
  final _expanded = <String>{};

  void _select(String label) {
    setState(() => _selected = label);
    if (MediaQuery.of(context).size.width <= 900) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    final sidebar = _Sidebar(
      selected: _selected,
      onSelect: _select,
      collapsed: wide && _collapsed,
      showCollapse: wide,
      expanded: _expanded,
      onToggleGroup: (g) => setState(() => _expanded.contains(g) ? _expanded.remove(g) : _expanded.add(g)),
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
    );

    return Scaffold(
      backgroundColor: AC.bg,
      drawer: wide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (wide) sidebar,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Topbar(showMenuButton: !wide),
                Expanded(
                  child: _selected == 'Dashboard'
                      ? const DashboardPage()
                      : _realPages[_selected]?.call() ?? _PlaceholderPage(title: _selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.onSelect,
    required this.collapsed,
    required this.showCollapse,
    required this.expanded,
    required this.onToggleGroup,
    required this.onToggleCollapse,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final bool collapsed;
  final bool showCollapse;
  final Set<String> expanded;
  final ValueChanged<String> onToggleGroup;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: collapsed ? 76 : 264,
      color: AC.navy900,
      child: Column(
        children: [
          Container(
            height: 76,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
            ),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB020), Color(0xFFFF7A1A)],
                    ),
                  ),
                  child: const Icon(Icons.home, color: Colors.white, size: 19),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Trusted Neighbourhood Network',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              children: [
                for (final item in navItems) _navTile(context, item),
              ],
            ),
          ),
          if (showCollapse)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onToggleCollapse,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0x0DFFFFFF),
                    foregroundColor: const Color(0xFFAEC0A8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, size: 16),
                  label: Text(collapsed ? '' : 'Collapse'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, NavItem item) {
    if (item.children.isEmpty) {
      final active = selected == item.label;
      return _tile(item.icon, item.label, active, () => onSelect(item.label));
    }
    final isOpen = expanded.contains(item.label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tile(item.icon, item.label, false, () => onToggleGroup(item.label),
            chevron: collapsed ? null : (isOpen ? Icons.expand_more : Icons.chevron_right)),
        if (isOpen && !collapsed)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0x14FFFFFF))),
              ),
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  for (final child in item.children)
                    _tile(null, child, selected == child, () => onSelect(child), dense: true),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tile(IconData? icon, String label, bool active, VoidCallback onTap,
      {IconData? chevron, bool dense = false}) {
    return Material(
      color: active ? AC.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 8 : 10),
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFFAEC0A8)),
              if (icon != null && !collapsed) const SizedBox(width: 12),
              if (!collapsed)
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dense ? 13 : 13.5,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : const Color(0xFFAEC0A8),
                    ),
                  ),
                ),
              if (chevron != null) Icon(chevron, size: 16, color: const Color(0xFF9DB098)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Topbar extends ConsumerWidget {
  const _Topbar({required this.showMenuButton});
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 76,
      color: AC.navy900,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) => _row(context, ref, constraints.maxWidth),
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, double availableWidth) {
    final showSearch = availableWidth > 620;
    final showProfileName = availableWidth > 460;

    return Row(
      children: [
        if (showMenuButton)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        Flexible(
          child: Text(
            'Super Admin Panel',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFB7C4AF), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        if (showSearch) ...[
          const SizedBox(width: 20),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF93A08E)),
                  hintText: 'Search anything...',
                  hintStyle: const TextStyle(color: Color(0xFF93A08E)),
                  filled: true,
                  fillColor: const Color(0x14FFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Searching for "$v"…')));
                },
              ),
            ),
          ),
        ],
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Notifications',
          icon: const _NotifIcon(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'verify', child: Text('15 providers awaiting verification')),
            PopupMenuItem(value: 'requests', child: Text('23 community requests need review')),
            PopupMenuItem(value: 'flagged', child: Text('8 items flagged for moderation')),
          ],
          onSelected: (_) {},
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          tooltip: 'Account',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: AC.blue,
                child: Text('SA',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              if (showProfileName) ...[
                const SizedBox(width: 10),
                const Text('Super Admin',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
              ],
              const Icon(Icons.expand_more, size: 16, color: Color(0xFF93A08E)),
            ],
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text('My Profile')),
            PopupMenuItem(value: 'settings', child: Text('Account Settings')),
            PopupMenuItem(value: 'audit', child: Text('Audit Logs')),
            PopupMenuItem(value: 'switch_role', child: Text('Switch role')),
            PopupMenuItem(value: 'signout', child: Text('Sign Out')),
          ],
          onSelected: (v) {
            if (v == 'switch_role') {
              ref.read(roleProvider.notifier).state = null;
              context.go('/role');
            } else if (v == 'signout') {
              ref.read(authControllerProvider.notifier).logout();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon.')),
              );
            }
          },
        ),
      ],
    );
  }
}

class _NotifIcon extends StatelessWidget {
  const _NotifIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined, color: Color(0xFFB7C4AF)),
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(color: AC.red, shape: BoxShape.circle),
            child: const Text('3',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 60),
      children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('This section is part of the prototype flow — wire up real data here next.',
            style: TextStyle(fontSize: 14, color: AC.ink600)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 30),
          decoration: BoxDecoration(
            border: Border.all(color: AC.line, style: BorderStyle.solid, width: 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(Icons.extension_outlined, size: 34, color: AC.ink600),
              const SizedBox(height: 14),
              Text('$title module',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'In the full build, this page would list and manage ${title.toLowerCase()} '
                'records with search, filters, and bulk actions — matching the same design '
                'system as the Dashboard.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AC.ink600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
