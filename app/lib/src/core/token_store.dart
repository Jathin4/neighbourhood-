import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Persists the access/refresh token pair in the platform secure store.
class TokenStore {
  static const _access = 'tnn_access';
  static const _refresh = 'tnn_refresh';
  final _storage = const FlutterSecureStorage();

  String? accessToken;

  Future<void> load() async {
    accessToken = await _storage.read(key: _access);
  }

  Future<String?> readRefresh() => _storage.read(key: _refresh);

  Future<void> save({required String access, required String refresh}) async {
    accessToken = access;
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<void> clear() async {
    accessToken = null;
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }

  bool get isLoggedIn => accessToken != null;
}
