import 'package:flutter/material.dart';

class AppTransitionPage extends StatelessWidget {
  final int page;
  final Widget child;

  const AppTransitionPage({super.key, required this.page, required this.child});

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 400);
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        final outgoing = child.key != ValueKey(page);
        return FadeTransition(
          opacity: animation,
          child: ExcludeSemantics(
            excluding: outgoing,
            child: ExcludeFocus(
              excluding: outgoing,
              child: IgnorePointer(ignoring: outgoing, child: child),
            ),
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          // Keep only the most recent outgoing page when tabs change quickly.
          if (previousChildren.isNotEmpty) previousChildren.last,
          ?currentChild,
        ],
      ),
      child: KeyedSubtree(
        key: ValueKey(page),
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
