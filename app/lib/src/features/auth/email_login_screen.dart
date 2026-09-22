import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../shared/auth_ui.dart';
import '../../shared/role.dart';
import 'auth_controller.dart';

/// Super Admin's own sign-in path — email+password, not phone OTP (§1).
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.contains('@') && _password.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithEmail(_email.text.trim(), _password.text);
      if (mounted) context.go('/');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);

    return AuthScaffold(
      badge: role?.label ?? 'Super Admin',
      hero: 'Staff sign in',
      sub: 'Use your work email and password.',
      onBack: () {
        ref.read(roleProvider.notifier).state = null;
        context.go('/role');
      },
      body: [
        const Text('Work email', style: fieldLabelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LC.ink),
          decoration: _fieldDecoration('name@tnnetwork.in'),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _canSubmit ? _submit() : null,
        ),
        const SizedBox(height: 16),
        const Text('Password', style: fieldLabelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: _password,
          obscureText: _obscure,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LC.ink),
          decoration: _fieldDecoration('••••••••••').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: LC.inkFaint, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _canSubmit ? _submit() : null,
        ),
        const SizedBox(height: 6),
        Text(
          _error ?? 'Passwords are never stored in plaintext.',
          style: _error != null ? helperErrorStyle : helperStyle,
        ),
      ],
      footer: AuthPrimaryButton(
        label: 'Continue',
        busy: _busy,
        onPressed: _canSubmit ? _submit : null,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: LC.inkFaint, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: LC.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LC.cardLine, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LC.cardLine, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: LC.accent, width: 1.5),
        ),
      );
}
