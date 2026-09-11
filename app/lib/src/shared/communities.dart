import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';

class Community {
  Community({required this.id, required this.name, this.address, required this.status});

  final String id;
  final String name;
  final String? address;
  final String status;

  factory Community.fromJson(Map<String, dynamic> j) => Community(
        id: j['id'] as String,
        name: j['name'] as String,
        address: j['address'] as String?,
        status: j['status'] as String,
      );
}

/// GET /communities — platform roles see every community, everyone else sees
/// only the communities they belong to.
final communitiesProvider = FutureProvider<List<Community>>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/communities');
    return (res.data as List)
        .map((e) => Community.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});
