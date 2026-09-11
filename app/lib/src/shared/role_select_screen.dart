import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'role.dart';

/// Shown once per sign-in: a real user can hold different roles across
/// communities, so this picks which role's screen to view this session.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Continue as')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final role in AppRole.values)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(role.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(roleProvider.notifier).state = role;
                  context.go('/');
                },
              ),
            ),
        ],
      ),
    );
  }
}
