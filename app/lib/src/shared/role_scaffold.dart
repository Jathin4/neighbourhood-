import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import 'me.dart';
import 'role.dart';

/// Common app bar (title + switch-role + sign-out) shared by every role home
/// except the Service Provider portal, which has its own tab-bar shell.
class RoleScaffold extends ConsumerWidget {
  const RoleScaffold({required this.title, required this.body, super.key});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account_outlined),
            tooltip: 'Switch role',
            onPressed: () {
              ref.read(roleProvider.notifier).state = null;
              context.go('/role');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: body,
    );
  }
}

/// Small "hello, name" header reused across role homes.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);
    return me.when(
      data: (m) =>
          Text('Hello, ${m.name ?? m.mobile}', style: Theme.of(context).textTheme.titleLarge),
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
    );
  }
}
