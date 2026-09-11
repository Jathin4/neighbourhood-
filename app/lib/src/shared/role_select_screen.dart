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
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              children: [
                Text(
                  'Trusted Neighbourhood Network',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continue as',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 620 ? 2 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: columns == 2 ? 2.6 : 3.2,
                      children: [
                        for (final role in AppRole.values)
                          _RoleCard(
                            role: role,
                            onTap: () {
                              ref.read(roleProvider.notifier).state = role;
                              context.go('/');
                            },
                          ),
                      ],
                    );
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

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role, required this.onTap});
  final AppRole role;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..translateByDouble(0.0, _hover ? -2.0 : 0.0, 0.0, 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hover ? role.color : const Color(0xFFE6E9F0), width: _hover ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: _hover ? role.color.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hover ? 18 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(role.icon, color: role.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(role.label,
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          role.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: role.color.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
