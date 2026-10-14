import 'package:mineral/features/executor/screens/executor_history_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/executor/widgets/executor_history_tile.dart';
import 'package:mineral/shared/data/demo_store.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/features/executor/screens/executor_screen.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'paused badge stays fully visible on one line at $width, scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = DemoStore();
          addTearDown(store.dispose);
          final order = store.assignedTo(1).first;
          order.status = OrderStatus.paused;
          store.orders.removeWhere((item) => item != order);
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('ru'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: ExecutorScreen(
                store: store,
                employeeId: 1,
                refreshOnOpen: false,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final badge = find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.data == 'Приостановлен' &&
                widget.style?.fontSize == 11,
          );
          expect(badge, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(badge);
          final boxes = paragraph.getBoxesForSelection(
            const TextSelection(
              baseOffset: 0,
              extentOffset: 'Приостановлен'.length,
            ),
          );
          expect(boxes.map((box) => box.top).toSet().length, 1);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('history filters have 48 logical pixel touch targets', (
    tester,
  ) async {
    final store = DemoStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: ExecutorHistoryScreen(
            orders: store.assignedTo(1),
            now: store.now,
            onRefresh: () async {},
            onOpen: (_) {},
            loadTime: (order) async => order,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final filter = find.widgetWithText(TextButton, 'Отменены');
    expect(tester.getSize(filter).height, greaterThanOrEqualTo(48));
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('home completed number reaches right inset at $width', (
      tester,
    ) async {
      final store = DemoStore();
      addTearDown(store.dispose);
      final order = store.assignedTo(1).first;
      order.status = OrderStatus.closed;
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ExecutorHistoryTile(
                    compact: true,
                    order: order,
                    now: store.now,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final card = tester.getRect(find.byType(ExecutorHistoryTile));
      final number = tester.getRect(find.text('Наряд №${order.displayNumber}'));
      expect(card.right - number.right, closeTo(8, 0.5));
      expect(tester.takeException(), isNull);
    });
  }
}
