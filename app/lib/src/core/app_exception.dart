import 'package:dio/dio.dart';

/// A user-presentable error mapped from the backend's `{error:{...}}` envelope.
class AppException implements Exception {
  AppException(this.code, this.message, {this.correlationId});

  final String code;
  final String message;
  final String? correlationId;

  factory AppException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return AppException(
        (err['code'] ?? 'error').toString(),
        (err['message'] ?? 'Request failed').toString(),
        correlationId: err['correlation_id']?.toString(),
      );
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return AppException('network', 'Cannot reach the server.');
    }
    return AppException('error', e.message ?? 'Something went wrong');
  }

  @override
  String toString() => message;
}
