import 'package:flutter/material.dart';

import '../data/pin_lock_controller.dart';
import '../screens/pin_lock_screen.dart';

/// Sits above the entire Navigator, including dialogs and notification routes.
/// Keeps the current form alive while the application is locked.
class PinLockGate extends StatefulWidget {
  const PinLockGate({
    super.key,
    required this.controller,
    required this.child,
    this.lockDelay = const Duration(seconds: 60),
    this.now,
  });
  final PinLockController controller;
  final Widget child;
  final Duration lockDelay;
  final DateTime Function()? now;

  @override
  State<PinLockGate> createState() => _PinLockGateState();
}

class _PinLockGateState extends State<PinLockGate> with WidgetsBindingObserver {
  bool _obscured = false;
  DateTime? _backgroundedAt;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= _now;
    } else if (state == AppLifecycleState.resumed) {
      final elapsed = _backgroundedAt == null
          ? null
          : _now.difference(_backgroundedAt!);
      if (elapsed != null &&
          (elapsed.isNegative || elapsed >= widget.lockDelay)) {
        widget.controller.lock();
      }
      _backgroundedAt = null;
    }
    // Always hide private content; a short camera visit keeps the session open.
    setState(() => _obscured = state != AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final blocking = widget.controller.blocking;
      final obscure = _obscured && widget.controller.session.authenticated;
      return Stack(
        fit: StackFit.expand,
        children: [
          Offstage(
            offstage: blocking || obscure,
            child: TickerMode(
              enabled: !blocking && !obscure,
              child: FocusScope(
                canRequestFocus: !blocking && !obscure,
                child: widget.child,
              ),
            ),
          ),
          if (blocking)
            PinLockScreen(
              key: ValueKey(
                '${widget.controller.status}:${widget.controller.session.user?.id}',
              ),
              controller: widget.controller,
            ),
          if (obscure)
            const Positioned.fill(
              child: ColoredBox(
                key: ValueKey('pin-privacy-cover'),
                color: Colors.white,
                child: Center(child: Icon(Icons.lock_outline, size: 48)),
              ),
            ),
        ],
      );
    },
  );
}
