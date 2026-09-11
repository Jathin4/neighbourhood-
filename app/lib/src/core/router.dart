import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/committee_member/committee_member_home.dart';
import '../features/community_admin/community_admin_home.dart';
import '../features/platform_ops/platform_ops_home.dart';
import '../features/provider/shell.dart';
import '../features/resident/resident_home.dart';
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
      if (atSplash) return '/';

      final signedIn = auth == AuthStatus.signedIn;
      final atLogin = state.matchedLocation == '/login' || state.matchedLocation == '/otp';
      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';

      // Signed in: a user can hold different roles per community, so pick
      // which role's screen to view once per session.
      final atRoleSelect = state.matchedLocation == '/role';
      if (role == null) return atRoleSelect ? null : '/role';
      if (atRoleSelect) return '/';
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
          AppRole.resident => const ResidentHome(),
          AppRole.communityAdmin => const CommunityAdminHome(),
          AppRole.committeeMember => const CommitteeMemberHome(),
          AppRole.provider => const ProviderShell(),
          AppRole.platformOps => const PlatformOpsHome(),
          AppRole.superAdmin => const SuperAdminHome(),
          null => const Scaffold(body: Center(child: CircularProgressIndicator())),
        },
      ),
    ],
  );
});
