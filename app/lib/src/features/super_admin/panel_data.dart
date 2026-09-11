import 'package:flutter/material.dart';

/// Super Admin Panel palette (mirrors the approved prototype).
abstract final class AC {
  static const navy900 = Color(0xFF0D1B34);
  static const bg = Color(0xFFF4F6FB);
  static const surface = Colors.white;
  static const ink900 = Color(0xFF101828);
  static const ink600 = Color(0xFF475467);
  static const ink400 = Color(0xFF98A2B3);
  static const line = Color(0xFFE6E9F0);
  static const blue = Color(0xFF2563EB);
  static const blue50 = Color(0xFFE9F0FF);
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

class StatCardData {
  const StatCardData(this.label, this.value, this.delta, this.up, this.icon, this.bg, this.fg);
  final String label;
  final String value;
  final String delta;
  final bool up;
  final IconData icon;
  final Color bg;
  final Color fg;
}

const mockStats = [
  StatCardData('Total Residents', '12,480', '+12%', true, Icons.groups_outlined, AC.blue50,
      AC.blue),
  StatCardData('Community Admins', '120', '+8%', true, Icons.shield_outlined, AC.purple50,
      AC.purple),
  StatCardData('Committee Members', '245', '+6%', true, Icons.diversity_3_outlined, AC.amber50,
      AC.amber),
  StatCardData('Service Providers', '420', '+14%', true, Icons.handyman_outlined, AC.teal50,
      AC.teal),
  StatCardData('Total Bookings', '3,650', '+18%', true, Icons.calendar_month_outlined, AC.red50,
      AC.red),
  StatCardData('Pending Provider Verifications', '15', '-40%', false, Icons.schedule_outlined,
      AC.amber50, AC.amber),
  StatCardData('Platform Revenue', '₹8,42,500', '+22%', true, Icons.currency_rupee, AC.blue50,
      AC.blue),
];

class ActivityRow {
  const ActivityRow(this.time, this.action, this.icon, this.color, this.bg, this.user, this.detail);
  final String time, action, user, detail;
  final IconData icon;
  final Color color, bg;
}

const mockActivity = [
  ActivityRow('Today, 10:24 AM', 'Provider Verified', Icons.check, AC.green, AC.green50,
      'ABC Plumbing Services', 'Provider ID: PRV-1024'),
  ActivityRow('Today, 09:18 AM', 'Community Created', Icons.apartment, AC.blue, AC.blue50,
      'Sunrise Towers', 'Community ID: COM-085'),
  ActivityRow('Today, 08:42 AM', 'New Booking', Icons.calendar_month, AC.purple, AC.purple50,
      'Rohit Sharma', 'Booking ID: BK-4587'),
  ActivityRow('Today, 07:15 AM', 'Refund Issued', Icons.currency_rupee, AC.amber, AC.amber50,
      'Priya Nair', 'Payment ID: PAY-7782'),
  ActivityRow('Yesterday, 06:32 PM', 'User Suspended', Icons.block, AC.red, AC.red50,
      'Suresh Kumar', 'Reason: Policy violation'),
];

class ApprovalItem {
  const ApprovalItem(this.title, this.sub, this.count, this.icon, this.bg, this.fg);
  final String title, sub;
  final int count;
  final IconData icon;
  final Color bg, fg;
}

const mockApprovals = [
  ApprovalItem('Provider Verifications', 'Require review', 15, Icons.handyman_outlined,
      AC.amber50, AC.amber),
  ApprovalItem('Community Requests', 'Require review', 23, Icons.apartment_outlined, AC.blue50,
      AC.blue),
  ApprovalItem('Resident Approvals', 'Require review', 42, Icons.groups_outlined, AC.green50,
      AC.green),
  ApprovalItem('Content Moderation', 'Flagged items', 8, Icons.shield_outlined, AC.purple50,
      AC.purple),
  ApprovalItem('Dispute Resolutions', 'Require action', 4, Icons.flag_outlined, AC.red50, AC.red),
];

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

/// Platform Growth series (mock — no analytics module yet, requirements §18).
const chartWeekLabels = ['Apr 27', 'May 4', 'May 11', 'May 18', 'May 25'];
const Map<String, List<double>> chartSeries = {
  'Users': [2200.0, 2900, 3600, 4400, 5300, 6600, 7100, 7700, 8300, 9100],
  'Bookings': [900.0, 1200, 1500, 1900, 2300, 2700, 3000, 3300, 3700, 4100],
  'Revenue': [300.0, 450, 600, 800, 1000, 1250, 1500, 1750, 2050, 2350],
};
const chartSeriesColors = {'Users': AC.blue, 'Bookings': AC.green, 'Revenue': AC.amber};
