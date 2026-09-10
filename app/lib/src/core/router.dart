import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/provider/shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final atSplash = state.matchedLocation == '/splash';
      if (auth == AuthStatus.unknown) return atSplash ? null : '/splash';
      if (atSplash) return '/';
      final signedIn = auth == AuthStatus.signedIn;
      final atLogin =
          state.matchedLocation == '/login' || state.matchedLocation == '/otp';
      if (!signedIn && !atLogin) return '/login';
      if (signedIn && atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(path: '/', builder: (_, __) => const ProviderShell()),
      GoRoute(path: '/login', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final args = (state.extra as Map?) ?? const {};
          return OtpScreen(
            mobile: args['mobile'] as String? ?? '',
            debugCode: args['debugCode'] as String?,
          );
        },
      ),
    ],
  );
});
