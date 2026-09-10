import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'token_store.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(tokenStoreProvider));
});

/// Thin Dio wrapper: attaches the bearer token and transparently refreshes it
/// once on a 401 before retrying the original request.
class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${Env.apiBaseUrl}/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.extra['retried'] != true) {
            if (await _refresh()) {
              final req = e.requestOptions..extra['retried'] = true;
              req.headers['Authorization'] = 'Bearer ${_tokens.accessToken}';
              try {
                return handler.resolve(await _dio.fetch(req));
              } on DioException catch (err) {
                return handler.next(err);
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  final TokenStore _tokens;
  late final Dio _dio;

  Dio get raw => _dio;

  Future<bool> _refresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: '${Env.apiBaseUrl}/api/v1'))
          .post('/auth/refresh', data: {'refresh_token': refresh});
      await _tokens.save(
        access: res.data['access_token'] as String,
        refresh: res.data['refresh_token'] as String,
      );
      return true;
    } on DioException {
      await _tokens.clear();
      return false;
    }
  }
}
