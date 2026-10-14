import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/shared/widgets/app_transition_page.dart';

Widget host(int page, {Widget? child, bool disableAnimations = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: AppTransitionPage(
            page: page,
            child: child ?? Center(child: Text('Page $page')),
          ),
        ),
      ),
    );

void main() {
  testWidgets('fade keeps each page mounted once without restarting loaders', (
    tester,
  ) async {
    final mounts = <int, int>{};
    Widget page(int index) => host(
      index,
      child: LoadingPage(
        onMount: () =>
            mounts.update(index, (count) => count + 1, ifAbsent: () => 1),
      ),
    );
    await tester.pumpWidget(page(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(page(1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(mounts, {0: 1, 1: 1});
    await tester.pumpAndSettle();
  });

  testWidgets('outgoing page remains visible until the new page fades in', (
    tester,
  ) async {
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Page 0'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    for (final text in ['Page 0', 'Page 1']) {
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));
    }
    await tester.pumpAndSettle();
    expect(find.text('Page 0'), findsNothing);
    expect(find.text('Page 1'), findsOneWidget);

    // A data rebuild in the current tab must not restart its animation.
    await tester.pumpWidget(
      host(1, child: const Center(child: Text('Updated'))),
    );
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Updated'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('outgoing controls cannot receive taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        0,
        child: Center(
          child: TextButton(
            onPressed: () => taps++,
            child: const Text('Old action'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final position = tester.getCenter(find.text('Old action'));
    await tester.pumpWidget(host(1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(position);
    expect(taps, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('rapid return to a page does not duplicate its global key', (
    tester,
  ) async {
    final key = GlobalKey();
    Widget page(int index) => host(
      index,
      child: Center(key: index == 2 ? key : null, child: Text('Page $index')),
    );
    await tester.pumpWidget(page(2));
    await tester.pumpAndSettle();
    for (final index in [0, 2, 1, 2, 0, 2]) {
      await tester.pumpWidget(page(index));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
      expect(
        find
            .descendant(
              of: find.byType(AppTransitionPage),
              matching: find.byType(Center),
            )
            .evaluate()
            .length,
        lessThanOrEqualTo(2),
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('reduced motion switches pages without a fade', (tester) async {
    await tester.pumpWidget(host(0, disableAnimations: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(1, disableAnimations: true));
    await tester.pump();
    expect(find.text('Page 0'), findsNothing);
    expect(find.text('Page 1'), findsOneWidget);
  });
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key, required this.onMount});
  final VoidCallback onMount;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
