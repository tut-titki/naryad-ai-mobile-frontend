import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mineral/core/theme/app_theme.dart';
import 'package:mineral/l10n/app_localizations.dart';

import '../data/pin_lock_controller.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key, required this.controller});
  final PinLockController controller;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _digits = '';
  String? _firstPin;
  bool _mismatch = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.controller.lockedUntil != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _waitSeconds {
    final until = widget.controller.lockedUntil;
    if (until == null) return 0;
    return (until.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(0, 60);
  }

  Future<void> _digit(String digit) async {
    final controller = widget.controller;
    if (controller.busy || _waitSeconds > 0 || _digits.length >= 4) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _mismatch = false;
      _digits += digit;
    });
    if (_digits.length != 4) return;
    final pin = _digits;
    if (controller.status == PinLockStatus.create) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = pin;
          _digits = '';
        });
        return;
      }
      if (_firstPin != pin) {
        setState(() {
          _mismatch = true;
          _digits = '';
        });
        return;
      }
    }
    await controller.submit(pin);
    if (mounted) setState(() => _digits = '');
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final s = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).height < 720;
    final creating = controller.status == PinLockStatus.create;
    final loading = controller.status == PinLockStatus.loading;
    final storageError = controller.status == PinLockStatus.storageError;
    final wait = _waitSeconds;
    final enabled = !loading && !storageError && !controller.busy && wait == 0;
    final title = creating
        ? (_firstPin == null ? s.pinCreateTitle : s.pinConfirmTitle)
        : s.pinEnterTitle;
    final message = storageError
        ? s.pinStorageError
        : wait > 0
        ? s.pinTryAgainSeconds('$wait')
        : _mismatch
        ? s.pinMismatch
        : controller.incorrect
        ? s.pinIncorrect
        : creating
        ? (_firstPin == null ? s.pinCreateHint : s.pinConfirmHint)
        : s.pinUnlockHint;

    return Scaffold(
      key: const ValueKey('pin-lock-screen'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: compact ? 16 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo_naryadAi.png',
                    height: compact ? 48 : 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (controller.session.user != null)
                    Text(
                      controller.session.user!.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: compact ? 40 : 56,
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              storageError ||
                                  _mismatch ||
                                  controller.incorrect ||
                                  wait > 0
                              ? Theme.of(context).colorScheme.error
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (loading || controller.busy)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Semantics(
                      label: s.pinDigitsEntered('${_digits.length}'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Container(
                              key: ValueKey('pin-dot-$i'),
                              margin: const EdgeInsets.symmetric(horizontal: 9),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < _digits.length
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (storageError)
                    FilledButton(
                      onPressed: controller.retry,
                      child: Text(s.retry),
                    )
                  else
                    for (final row in ['123', '456', '789', ' 0<'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final digit in row.split(''))
                              SizedBox(
                                width: 80,
                                height: compact ? 56 : 64,
                                child: digit == ' '
                                    ? const SizedBox.shrink()
                                    : TextButton(
                                        key: ValueKey('pin-key-$digit'),
                                        onPressed: !enabled
                                            ? null
                                            : digit == '<'
                                            ? () => setState(() {
                                                if (_digits.isNotEmpty) {
                                                  _digits = _digits.substring(
                                                    0,
                                                    _digits.length - 1,
                                                  );
                                                }
                                              })
                                            : () => _digit(digit),
                                        style: TextButton.styleFrom(
                                          backgroundColor: AppColors.background,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                        ),
                                        child: digit == '<'
                                            ? Icon(
                                                Icons.backspace_outlined,
                                                semanticLabel: s.pinDeleteDigit,
                                              )
                                            : Text(
                                                digit,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                ),
                                              ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 16),
                  if (creating && _firstPin != null)
                    TextButton(
                      key: const ValueKey('pin-change'),
                      onPressed: !enabled
                          ? null
                          : () => setState(() {
                              _firstPin = null;
                              _digits = '';
                              _mismatch = false;
                            }),
                      child: Text(s.pinChange),
                    ),
                  TextButton(
                    key: const ValueKey('pin-forgot'),
                    onPressed: controller.busy
                        ? null
                        : creating
                        ? controller.useAnotherAccount
                        : controller.forgotPin,
                    child: Text(
                      creating ? s.pinUseAnotherAccount : s.pinForgot,
                    ),
                  ),
                  if (!creating)
                    Text(
                      s.pinResetHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
