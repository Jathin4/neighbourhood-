import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/token_store.dart';
import '../../shared/role.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

final authControllerProvider =
    NotifierProvider<AuthController, AuthStatus>(AuthController.new);

class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    _restore();
    return AuthStatus.unknown;
  }

  Future<void> _restore() async {
    final store = ref.read(tokenStoreProvider);
    await store.load();
    state = store.isLoggedIn ? AuthStatus.signedIn : AuthStatus.signedOut;
  }

  Future<String?> requestOtp(String mobile) =>
      ref.read(authRepositoryProvider).requestOtp(mobile);

  Future<void> verifyOtp(String mobile, String code) async {
    await ref.read(authRepositoryProvider).verifyOtp(mobile, code);
    state = AuthStatus.signedIn;
  }

  Future<void> loginWithEmail(String email, String password) async {
    await ref.read(authRepositoryProvider).loginWithEmail(email, password);
    state = AuthStatus.signedIn;
  }

  Future<void> devLogin(String mobile) async {
    await ref.read(authRepositoryProvider).devLogin(mobile);
    state = AuthStatus.signedIn;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(roleProvider.notifier).state = null;
    state = AuthStatus.signedOut;
  }
}
