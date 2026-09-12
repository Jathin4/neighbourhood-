import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../shared/auth_ui.dart';
import '../../shared/role.dart';
import 'auth_controller.dart';

/// Keeps the "+91 " prefix fixed and only lets the resident type digits after
/// it; the API still gets the number with no space (see [_PhoneScreenState._mobile]).
class _Plus91Formatter extends TextInputFormatter {
  static const _prefix = '+91 ';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    // Only the part after the fixed prefix is real user input; strip that,
    // not the whole string (which would re-count the prefix's own "91").
    final rest = raw.startsWith(_prefix) ? raw.substring(_prefix.length) : raw;
    final digitsRaw = rest.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = digitsRaw.length > 10 ? digitsRaw.substring(0, 10) : digitsRaw;
    final text = '$_prefix$digits';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController(text: '+91 ');
  bool _busy = false;
  String? _error;

  String get _mobile => _controller.text.replaceAll(' ', '');
  int get _digitCount => _mobile.length - 3; // strip "+91"

  Future<void> _submit() async {
    final mobile = _mobile;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final debugCode = await ref.read(authControllerProvider.notifier).requestOtp(mobile);
      if (mounted) {
        context.push('/otp', extra: {'mobile': mobile, 'debugCode': debugCode});
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _devLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).devLogin(_mobile);
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
      badge: role?.label ?? 'Trusted Neighbourhood Network',
      hero: 'Verify your number',
      sub: "We'll send a one-time code to confirm it's you.",
      onBack: () {
        ref.read(roleProvider.notifier).state = null;
        context.go('/role');
      },
      body: [
        const Text('Mobile number', style: fieldLabelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [_Plus91Formatter()],
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LC.ink),
          decoration: InputDecoration(
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
          ),
          onSubmitted: (_) => _digitCount == 10 ? _submit() : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Text(
          _error ?? 'Standard OTP rates may apply.',
          style: _error != null ? helperErrorStyle : helperStyle,
        ),
      ],
      footer: Column(
        children: [
          AuthPrimaryButton(
            label: 'Send OTP',
            busy: _busy,
            onPressed: _digitCount == 10 ? _submit : null,
          ),
          TextButton(
            onPressed: _busy ? null : _devLogin,
            child: const Text('Skip OTP — dev sign in',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: LC.inkSoft)),
          ),
        ],
      ),
    );
  }
}
