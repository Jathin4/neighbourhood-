import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
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
    final digits = rest.replaceAll(RegExp(r'[^0-9]'), '');
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Trusted Neighbourhood Network',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in with your mobile number',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_Plus91Formatter()],
                  decoration: const InputDecoration(labelText: 'Mobile number'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
                TextButton(
                  onPressed: _busy ? null : _devLogin,
                  child: const Text('Skip OTP — dev sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
