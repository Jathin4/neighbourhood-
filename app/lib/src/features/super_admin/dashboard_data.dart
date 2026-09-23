import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';

class DashboardStats {
  DashboardStats({
    required this.totalCommunities,
    required this.totalResidents,
    required this.communityAdmins,
    required this.committeeMembers,
    required this.serviceProviders,
    required this.totalBookings,
    required this.pendingMembershipApprovals,
  });

  final int totalCommunities;
  final int totalResidents;
  final int communityAdmins;
  final int committeeMembers;
  final int serviceProviders;
  final int totalBookings;
  final int pendingMembershipApprovals;

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        totalCommunities: j['total_communities'] as int,
        totalResidents: j['total_residents'] as int,
        communityAdmins: j['community_admins'] as int,
        committeeMembers: j['committee_members'] as int,
        serviceProviders: j['service_providers'] as int,
        totalBookings: j['total_bookings'] as int,
        pendingMembershipApprovals: j['pending_membership_approvals'] as int,
      );
}

/// GET /admin/dashboard-stats — real counts from the database, no fabricated
/// deltas (there's no historical snapshot to compare against yet).
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/admin/dashboard-stats');
    return DashboardStats.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

class GrowthSeries {
  GrowthSeries({required this.labels, required this.newUsers, required this.newBookings});

  final List<String> labels;
  final List<int> newUsers;
  final List<int> newBookings;

  factory GrowthSeries.fromJson(Map<String, dynamic> j) => GrowthSeries(
        labels: (j['labels'] as List).cast<String>(),
        newUsers: (j['new_users'] as List).cast<int>(),
        newBookings: (j['new_bookings'] as List).cast<int>(),
      );
}

/// GET /admin/growth-series — real daily new-user/new-booking counts. No
/// revenue series: there's no payments/commission model yet to back one.
final growthSeriesProvider = FutureProvider<GrowthSeries>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/admin/growth-series');
    return GrowthSeries.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

class AuditEntry {
  AuditEntry(this.action, this.entity, this.entityId, this.actorMobile, this.createdAt, this.meta);
  final String action, entity;
  final String? entityId, actorMobile;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
        j['action'] as String,
        j['entity'] as String,
        j['entity_id'] as String?,
        j['actor_mobile'] as String?,
        DateTime.parse(j['created_at'] as String).toLocal(),
        Map<String, dynamic>.from(j['meta'] as Map? ?? {}),
      );
}

/// GET /admin/audit-logs — the same real feed as the Audit Logs page, capped
/// to a handful of rows for the dashboard's "Recent Activity" card.
final recentActivityProvider = FutureProvider<List<AuditEntry>>((ref) async {
  try {
    final res =
        await ref.read(apiClientProvider).raw.get('/admin/audit-logs', queryParameters: {'limit': 8});
    return (res.data as List).map((e) => AuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});
