import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/app_exception.dart';

class Me {
  Me({
    required this.id,
    required this.mobile,
    this.name,
    this.email,
    this.status,
    this.platformRole,
  });

  final String id;
  final String mobile;
  final String? name;
  final String? email;
  final String? status;
  final String? platformRole;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: j['id'] as String,
        mobile: j['mobile'] as String,
        name: j['name'] as String?,
        email: j['email'] as String?,
        status: j['status'] as String?,
        platformRole: j['platform_role'] as String?,
      );
}

/// GET /users/me — used by every role's home screen for the greeting.
final meProvider = FutureProvider<Me>((ref) async {
  try {
    final res = await ref.read(apiClientProvider).raw.get('/users/me');
    return Me.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw AppException.fromDio(e);
  }
});
