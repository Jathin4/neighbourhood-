import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_ui.dart';
import 'role.dart';

/// Shown once per sign-in: a real user can hold different roles across
/// communities, so this picks which role's screen to view this session.
/// Visual design matches the approved login prototype.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LC.bgFrame,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              children: [
                Text('Continue as', style: heroStyle(size: 30)),
                const SizedBox(height: 4),
                const Text(
                  "Choose how you're accessing Trusted Neighbourhood Network.",
                  style: subStyle,
                ),
                const SizedBox(height: 20),
                for (final role in AppRole.values)
                  _RoleCard(
                    role: role,
                    onTap: () {
                      ref.read(roleProvider.notifier).state = role;
                      context.go('/');
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onTap});
  final AppRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: LC.card,
        border: Border.all(color: LC.cardLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: LC.ink)),
                      const SizedBox(height: 3),
                      Text(role.description,
                          style: const TextStyle(fontSize: 12.5, color: LC.inkSoft, height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right, color: LC.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
