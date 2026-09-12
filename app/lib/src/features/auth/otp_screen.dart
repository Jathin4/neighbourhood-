import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_exception.dart';
import '../../shared/auth_ui.dart';
import '../../shared/role.dart';
import 'auth_controller.dart';

const _codeLength = 6; // matches backend settings.otp_length

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.mobile, this.debugCode});

  final String mobile;
  final String? debugCode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final _controllers = List.generate(_codeLength, (_) => TextEditingController());
  late final _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  bool _busy = false;
  bool _verified = false;
  String? _error;
  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    if (widget.debugCode != null) {
      for (var i = 0; i < _codeLength && i < widget.debugCode!.length; i++) {
        _controllers[i].text = widget.debugCode![i];
      }
    }
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(widget.mobile);
      _startTimer();
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(widget.mobile, _code);
      if (!mounted) return;
      setState(() => _verified = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/');
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verified) return const _VerifiedScreen();

    final role = ref.watch(roleProvider);
    final complete = _code.length == _codeLength;

    return AuthScaffold(
      badge: role?.label ?? 'Trusted Neighbourhood Network',
      hero: 'Enter the code',
      sub: 'We sent a code by SMS to +91 ${widget.mobile.replaceFirst('+91', '')}.',
      body: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _codeLength; i++) _otpBox(i),
          ],
        ),
        const SizedBox(height: 10),
        if (_error != null)
          Text(_error!, style: helperErrorStyle)
        else if (widget.debugCode != null)
          Text('Dev code: ${widget.debugCode}', style: helperStyle),
        const SizedBox(height: 8),
        _secondsLeft > 0
            ? Text('Resend code in ${_secondsLeft}s',
                style: const TextStyle(fontSize: 13, color: LC.inkFaint, fontWeight: FontWeight.w700))
            : InkWell(
                onTap: _resend,
                child: const Text('Resend code',
                    style:
                        TextStyle(fontSize: 13, color: LC.accent, fontWeight: FontWeight.w700)),
              ),
      ],
      footer: AuthPrimaryButton(
        label: 'Verify & continue',
        busy: _busy,
        onPressed: complete ? _submit : null,
      ),
    );
  }

  Widget _otpBox(int i) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _controllers[i],
        focusNode: _focusNodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LC.ink),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: LC.card,
          contentPadding: EdgeInsets.zero,
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
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && i + 1 < _codeLength) {
            _focusNodes[i + 1].requestFocus();
          } else if (value.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
          }
        },
      ),
    );
  }
}

class _VerifiedScreen extends StatelessWidget {
  const _VerifiedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LC.bgFrame,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: LC.accent, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: LC.accentInk, size: 34),
            ),
            const SizedBox(height: 22),
            Text('Verified', style: heroStyle(size: 22)),
            const SizedBox(height: 6),
            const Text('Setting up your dashboard…', style: subStyle),
          ],
        ),
      ),
    );
  }
}
