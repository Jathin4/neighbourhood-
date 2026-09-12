import 'package:flutter/material.dart';

/// Shared visual language for the auth flow (role picker → sign in → OTP),
/// per the approved login prototype. Deliberately separate from the
/// per-role portal palettes (ticket_ui.dart, panel_data.dart) — only the
/// auth screens use this.
abstract final class LC {
  static const bgFrame = Color(0xFFF4F7EF);
  static const ink = Color(0xFF1D2A1C);
  static const inkSoft = Color(0xFF5B6B58);
  static const inkFaint = Color(0xFF93A08E);
  static const card = Colors.white;
  static const cardLine = Color(0xFFDFE6D6);
  static const accent = Color(0xFF2F5D3A);
  static const accentInk = Color(0xFFF4F7EF);
  static const accentSoft = Color(0xFFE3ECDC);
  static const error = Color(0xFFA13A3A);
}

/// Prototype pairs a serif display face with a sans body face. Using the
/// platform's generic "serif" family keeps that contrast without adding a
/// google_fonts dependency for two headings.
const _serif = 'serif';

TextStyle heroStyle({double size = 28}) => TextStyle(
      fontFamily: _serif,
      fontWeight: FontWeight.w600,
      fontSize: size,
      color: LC.ink,
      height: 1.15,
    );

const subStyle = TextStyle(fontSize: 14.5, color: LC.inkSoft, height: 1.5);
const fieldLabelStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: LC.inkSoft);
const helperStyle = TextStyle(fontSize: 12, color: LC.inkFaint);
const helperErrorStyle = TextStyle(fontSize: 12.5, color: LC.error);

/// Small pill showing which role is signing in (prototype's `.badge`).
class RoleBadge extends StatelessWidget {
  const RoleBadge(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(color: LC.accentSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: LC.accent)),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({required this.label, required this.onPressed, this.busy = false, super.key});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LC.accent,
          disabledBackgroundColor: LC.accent.withValues(alpha: 0.4),
          foregroundColor: LC.accentInk,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: LC.accentInk),
              )
            : Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(backgroundColor: LC.accentSoft, foregroundColor: LC.accent),
          icon: const Icon(Icons.arrow_back, size: 18),
        ),
      ),
    );
  }
}

/// The content column layout every auth screen shares: badge, hero, sub,
/// body, spacer, primary action pinned to the bottom.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.badge,
    required this.hero,
    required this.sub,
    required this.body,
    this.onBack,
    this.footer,
    super.key,
  });

  final String badge;
  final String hero;
  final String sub;
  final List<Widget> body;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LC.bgFrame,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                if (onBack != null) AuthBackButton(onPressed: onBack!),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoleBadge(badge),
                        const SizedBox(height: 10),
                        Text(hero, style: heroStyle()),
                        const SizedBox(height: 4),
                        Text(sub, style: subStyle),
                        const SizedBox(height: 20),
                        ...body,
                        const Spacer(),
                        if (footer != null) footer!,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
