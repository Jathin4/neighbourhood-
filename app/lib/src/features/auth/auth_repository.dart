import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../core/token_store.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(tokenStoreProvider));
});

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  /// Returns the dev `debug_code` when the backend runs with OTP_DEBUG=true.
  Future<String?> requestOtp(String mobile) async {
    try {
      final res = await _api.raw.post(
        '/auth/otp/request',
        data: {'mobile': mobile},
      );
      return res.data['debug_code'] as String?;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// Dev-only: backend skips OTP and returns tokens straight away.
  Future<void> devLogin(String mobile) async {
    try {
      final res = await _api.raw.post('/auth/dev-login', data: {'mobile': mobile});
      await _tokens.save(
        access: res.data['access_token'] as String,
        refresh: res.data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> verifyOtp(String mobile, String code) async {
    try {
      final res = await _api.raw.post(
        '/auth/otp/verify',
        data: {'mobile': mobile, 'code': code},
      );
      await _tokens.save(
        access: res.data['access_token'] as String,
        refresh: res.data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefresh();
    if (refresh != null) {
      try {
        await _api.raw.post('/auth/logout', data: {'refresh_token': refresh});
      } on DioException {
        // best effort
      }
    }
    await _tokens.clear();
  }
}
