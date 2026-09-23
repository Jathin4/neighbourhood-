import 'package:flutter/material.dart';

/// Super Admin Panel palette — brand slots (navy900/bg/surface/ink*/line/
/// blue*) recolored to the same earthy-green palette as shared/auth_ui.dart's
/// LC.* so the console matches the rest of the app; the remaining hues
/// (green/purple/amber/red/teal) stay as category/status color-coding.
abstract final class AC {
  static const navy900 = Color(0xFF16311D);
  static const bg = Color(0xFFF4F7EF);
  static const surface = Colors.white;
  static const ink900 = Color(0xFF1D2A1C);
  static const ink600 = Color(0xFF5B6B58);
  static const ink400 = Color(0xFF93A08E);
  static const line = Color(0xFFDFE6D6);
  static const blue = Color(0xFF2F5D3A);
  static const blue50 = Color(0xFFE3ECDC);
  static const green = Color(0xFF12875A);
  static const green50 = Color(0xFFE5F7EE);
  static const purple = Color(0xFF7C5CFF);
  static const purple50 = Color(0xFFEFEAFF);
  static const amber = Color(0xFFC98A12);
  static const amber50 = Color(0xFFFDF1DE);
  static const red = Color(0xFFE5484D);
  static const red50 = Color(0xFFFDEAEA);
  static const teal = Color(0xFF0F9D9D);
  static const teal50 = Color(0xFFE3F7F7);
}

class NavItem {
  const NavItem(this.label, this.icon, {this.children = const []});
  final String label;
  final IconData icon;
  final List<String> children;
}

const navItems = [
  NavItem('Dashboard', Icons.space_dashboard_outlined),
  NavItem('User Management', Icons.people_outline, children: [
    'All Users', 'Residents', 'Community Admins', 'Committee Members',
    'Service Providers', 'Platform Operations', 'Super Admins',
  ]),
  NavItem('Community Management', Icons.apartment_outlined,
      children: ['Communities', 'Announcements', 'Amenities']),
  NavItem('Provider Management', Icons.handyman_outlined,
      children: ['Providers', 'Verification Queue', 'Categories']),
  NavItem('Marketplace', Icons.storefront_outlined, children: ['Listings', 'Orders']),
  NavItem('Bookings', Icons.calendar_month_outlined, children: ['All Bookings', 'Calendar']),
  NavItem('Payments & Settlement', Icons.credit_card_outlined,
      children: ['Transactions', 'Payouts']),
  NavItem('Issues & Complaints', Icons.report_problem_outlined,
      children: ['Open Tickets', 'Resolved']),
  NavItem('Content & Moderation', Icons.shield_outlined,
      children: ['Flagged Items', 'Reports']),
  NavItem('Notifications', Icons.notifications_outlined, children: ['Templates', 'History']),
  NavItem('RBAC & Permissions', Icons.lock_outline, children: ['Roles', 'Permissions']),
  NavItem('Analytics', Icons.bar_chart_outlined),
  NavItem('Audit Logs', Icons.fact_check_outlined),
  NavItem('Configuration', Icons.settings_outlined, children: ['General', 'Integrations']),
  NavItem('Settings', Icons.build_outlined),
];

// Illustrative only — no infra-monitoring backend exists to check these
// against, unlike the dashboard stats/activity/growth data (see
// dashboard_data.dart), which are real.
const healthItems = [
  ('API Services', Icons.dns_outlined),
  ('Database', Icons.storage_outlined),
  ('Redis Cache', Icons.inventory_2_outlined),
  ('Background Jobs', Icons.settings_outlined),
  ('Storage (S3)', Icons.cloud_outlined),
  ('Notification Services', Icons.notifications_outlined),
];

class QuickActionData {
  const QuickActionData(this.label, this.icon, this.bg, this.fg);
  final String label;
  final IconData icon;
  final Color bg, fg;
}

const quickActions = [
  QuickActionData('Create Community', Icons.apartment_outlined, AC.green50, AC.green),
  QuickActionData('Create User', Icons.person_add_alt_outlined, AC.blue50, AC.blue),
  QuickActionData('Add Service Provider', Icons.handyman_outlined, AC.teal50, AC.teal),
  QuickActionData('Configure Categories', Icons.folder_outlined, AC.purple50, AC.purple),
  QuickActionData('Manage Roles & Permissions', Icons.lock_outline, AC.amber50, AC.amber),
  QuickActionData('View Audit Logs', Icons.description_outlined, AC.red50, AC.red),
];
