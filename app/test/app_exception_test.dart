import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnn_app/src/core/app_exception.dart';

void main() {
  final req = RequestOptions(path: '/x');

  test('maps the backend error envelope', () {
    final e = DioException(
      requestOptions: req,
      response: Response(
        requestOptions: req,
        statusCode: 400,
        data: {
          'error': {
            'code': 'otp_invalid',
            'message': 'Incorrect OTP',
            'correlation_id': 'abc123',
          },
        },
      ),
    );
    final mapped = AppException.fromDio(e);
    expect(mapped.code, 'otp_invalid');
    expect(mapped.message, 'Incorrect OTP');
    expect(mapped.correlationId, 'abc123');
  });

  test('falls back to a friendly network message', () {
    final e = DioException(
      requestOptions: req,
      type: DioExceptionType.connectionError,
      message: 'boom',
    );
    expect(AppException.fromDio(e).code, 'network');
  });
}
