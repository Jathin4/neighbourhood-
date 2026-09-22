import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';
import 'ticket_ui.dart' show TStatus;

/// A resident's service request. Unclaimed (providerUserId is null) until a
/// provider whose category matches accepts it — matches
/// backend/app/models/marketplace.py's open lead-pool model.
class MarketBooking {
  MarketBooking({
    required this.id,
    required this.providerUserId,
    required this.category,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.residentName,
    this.providerName,
  });

  final String id;
  final String? providerUserId;
  final String category;
  final String title;
  final String status; // requested | accepted | completed | cancelled
  final DateTime createdAt;
  final String residentName;
  final String? providerName;

  factory MarketBooking.fromJson(Map<String, dynamic> j) => MarketBooking(
        id: j['id'] as String,
        providerUserId: j['provider_user_id'] as String?,
        category: j['category'] as String,
        title: j['title'] as String,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        residentName: j['resident_name'] as String,
        providerName: j['provider_name'] as String?,
      );
}

class MyProviderProfile {
  MyProviderProfile({required this.businessName, required this.category});
  final String businessName;
  final String category;

  factory MyProviderProfile.fromJson(Map<String, dynamic> j) => MyProviderProfile(
        businessName: j['business_name'] as String,
        category: j['category'] as String,
      );
}

/// GET /marketplace/providers/me — null when this user hasn't registered as
/// a provider yet (404).
final myProviderProfileProvider = FutureProvider<MyProviderProfile?>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/marketplace/providers/me');
    return MyProviderProfile.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    throw AppException.fromDio(e);
  }
});

/// GET /bookings/mine — every booking I raised as a resident (any status).
final myBookingsProvider = FutureProvider<List<MarketBooking>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/bookings/mine');
    return (res.data as List)
        .map((e) => MarketBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// Registers the current user as a provider the first time they open the
/// Service Provider portal, so their leads/bookings calls have a category to
/// match against. Matches the identity already shown in the Profile screen.
final ensureProviderRegisteredProvider = FutureProvider<MyProviderProfile>((ref) async {
  final existing = await ref.watch(myProviderProfileProvider.future);
  if (existing != null) return existing;
  try {
    final res = await ref.read(apiClientProvider).raw.put('/marketplace/providers/me', data: {
      'business_name': 'Ramesh Kumar Electricals',
      'category': 'Electrician',
    });
    ref.invalidate(myProviderProfileProvider);
    return MyProviderProfile.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// GET /bookings/leads — open, unclaimed requests matching my provider
/// category. Auto-registers as a provider first if this user isn't one yet.
final myLeadsProvider = FutureProvider<List<MarketBooking>>((ref) async {
  await ref.watch(ensureProviderRegisteredProvider.future);
  try {
    final res = await ref.read(apiClientProvider).raw.get('/bookings/leads');
    return (res.data as List)
        .map((e) => MarketBooking.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});

/// Resident's ServiceCategory.name / a provider's registered category ->
/// shared/ticket_ui.dart's catIcon() code. Shared between the Resident and
/// Service Provider portals so a booking looks the same icon on both sides.
const marketCategoryIcon = {
  'Electrician': 'bolt',
  'Plumber': 'wrench',
  'Carpenter': 'wrench',
  'AC Technician': 'fan',
  'Pest Control': 'spray',
  'Cleaning': 'build',
};

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String fmtBookingWhen(DateTime dt) {
  final local = dt.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour < 12 ? 'AM' : 'PM';
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthNames[local.month - 1]}, $hour12:$minute $ampm';
}

(TStatus, String) bookingStatusInfo(String status) => switch (status) {
      'accepted' => (TStatus.amber, 'Accepted'),
      'completed' => (TStatus.success, 'Completed'),
      'cancelled' => (TStatus.danger, 'Cancelled'),
      _ => (TStatus.blue, 'Requested'),
    };
