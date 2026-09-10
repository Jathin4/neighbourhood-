import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import 'auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.mobile, this.debugCode});

  final String mobile;
  final String? debugCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final _controller = TextEditingController(text: widget.debugCode ?? '');
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(widget.mobile, _controller.text.trim());
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
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Code sent to ${widget.mobile}'),
                if (widget.debugCode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dev code: ${widget.debugCode}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'OTP'),
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
                      : const Text('Verify & continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
