import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';
import 'ticket_ui.dart' show TStatus;

(TStatus, String) issueStatusInfo(String status) => switch (status) {
      'in_progress' => (TStatus.amber, 'In Progress'),
      'resolved' => (TStatus.success, 'Resolved'),
      'reopened' => (TStatus.blue, 'Reopened'),
      _ => (TStatus.blue, 'Submitted'),
    };

class CommunityNotice {
  CommunityNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.priority,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String priority; // general | critical
  final DateTime createdAt;
  final bool read;

  factory CommunityNotice.fromJson(Map<String, dynamic> j) => CommunityNotice(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        priority: j['priority'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        read: j['read'] as bool,
      );
}

class CommunityEvent {
  CommunityEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.location,
    required this.rsvpCount,
    required this.rsvped,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final String location;
  final int rsvpCount;
  final bool rsvped;

  factory CommunityEvent.fromJson(Map<String, dynamic> j) => CommunityEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        startsAt: DateTime.parse(j['starts_at'] as String),
        location: j['location'] as String,
        rsvpCount: j['rsvp_count'] as int,
        rsvped: j['rsvped'] as bool,
      );
}

class CommunityIssue {
  CommunityIssue({
    required this.id,
    required this.communityId,
    required this.raisedByName,
    required this.category,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String communityId;
  final String raisedByName;
  final String category;
  final String title;
  final String status; // submitted | in_progress | resolved | reopened
  final DateTime createdAt;

  factory CommunityIssue.fromJson(Map<String, dynamic> j) => CommunityIssue(
        id: j['id'] as String,
        communityId: j['community_id'] as String,
        raisedByName: j['raised_by_name'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// GET /communities/{id}/notices
final noticesProvider =
    FutureProvider.family<List<CommunityNotice>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/communities/$communityId/notices');
    return (res.data as List)
        .map((e) => CommunityNotice.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// GET /communities/{id}/events
final eventsProvider =
    FutureProvider.family<List<CommunityEvent>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/communities/$communityId/events');
    return (res.data as List)
        .map((e) => CommunityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// GET /issues/mine — every issue I raised as a resident.
final myIssuesProvider = FutureProvider<List<CommunityIssue>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/issues/mine');
    return (res.data as List)
        .map((e) => CommunityIssue.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// GET /issues?community_id= — the full queue for whoever can manage issues.
final communityIssuesProvider =
    FutureProvider.family<List<CommunityIssue>, String>((ref, communityId) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get(
      '/issues',
      queryParameters: {'community_id': communityId},
    );
    return (res.data as List)
        .map((e) => CommunityIssue.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});
