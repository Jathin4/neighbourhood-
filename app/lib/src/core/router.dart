import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/email_login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/committee_member/committee_member_shell.dart';
import '../features/community_admin/community_admin_shell.dart';
import '../features/platform_ops/platform_ops_shell.dart';
import '../features/provider/shell.dart';
import '../features/resident/shell.dart';
import '../features/super_admin/super_admin_home.dart';
import '../shared/role.dart';
import '../shared/role_select_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final role = ref.watch(roleProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final atSplash = state.matchedLocation == '/splash';
      if (auth == AuthStatus.unknown) return atSplash ? null : '/splash';

      // Role picker comes first on every cold start (roleProvider resets to
      // null on launch and on logout) — login only follows if needed.
      final atRoleSelect = state.matchedLocation == '/role';
      if (role == null) return atRoleSelect ? null : '/role';

      final signedIn = auth == AuthStatus.signedIn;
      // Super Admin signs in with email+password; every other role uses phone OTP.
      final loginPath = role == AppRole.superAdmin ? '/login-email' : '/login';
      final atLogin = state.matchedLocation == '/login' ||
          state.matchedLocation == '/login-email' ||
          state.matchedLocation == '/otp';
      if (!signedIn) return atLogin ? null : loginPath;
      if (atLogin || atRoleSelect) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(path: '/login', builder: (_, __) => const PhoneScreen()),
      GoRoute(path: '/login-email', builder: (_, __) => const EmailLoginScreen()),
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
      GoRoute(path: '/role', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: '/',
        builder: (_, __) => switch (role) {
          AppRole.resident => const ResidentShell(),
          AppRole.communityAdmin => const CommunityAdminShell(),
          AppRole.committeeMember => const CommitteeMemberShell(),
          AppRole.provider => const ProviderShell(),
          AppRole.platformOps => const PlatformOpsShell(),
          AppRole.superAdmin => const SuperAdminHome(),
          null => const Scaffold(body: Center(child: CircularProgressIndicator())),
        },
      ),
    ],
  );
});
