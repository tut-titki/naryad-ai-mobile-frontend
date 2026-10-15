import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/orders/screens/orders_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'helpers/backend_api_fixture.dart';

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void viewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'kanban columns stay fixed while their orders scroll independently',
    (tester) async {
      viewport(tester, 1400);
      int? opened;
      var creates = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders') return jsonResponse([]);
          if (request.url.path == '/api/work-orders/board') {
            final board = boardJson(
              issued: List.generate(20, (i) => orderJson(id: i + 1)),
            );
            (board['columns'] as Map)['accepted'] = List.generate(
              20,
              (i) => orderJson(id: i + 101, status: 'ACCEPTED'),
            );
            return jsonResponse(board);
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: OrdersScreen(
              api: api,
              onOrder: (order) => opened = order.id,
              onCreate: () => creates++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Назначения, сроки и текущие статусы работ'),
        findsNothing,
      );
      expect(find.text('Список нарядов'), findsNothing);
      expect(find.text('Доска нарядов'), findsNothing);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Список'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Канбан'), findsOneWidget);
      final createButton = find.byKey(
        const ValueKey('orders-create-order-fab'),
      );
      expect(createButton, findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Новый наряд'), findsNothing);
      final createRect = tester.getRect(createButton);
      await tester.tap(find.text('Новый наряд'));
      expect(creates, 1);
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      expect(tester.getRect(createButton), createRect);
      final columns = [
        'issued',
        'accepted',
        'inProgress',
        'queued',
        'completed',
        'overdue',
      ];
      final sizes = [
        for (final id in columns)
          tester.getSize(find.byKey(ValueKey('kanban-column-$id'))),
      ];
      expect(sizes.toSet().length, 1);
      expect(sizes.first.height, lessThan(844));
      expect(sizes.first.width, lessThanOrEqualTo(300));
      final firstList = find.byKey(
        const PageStorageKey('kanban-orders-issued'),
      );
      final secondList = find.byKey(
        const PageStorageKey('kanban-orders-accepted'),
      );
      final header = find.byKey(const ValueKey('kanban-header-issued'));
      final headerBefore = tester.getRect(header);
      final firstController = tester.widget<ListView>(firstList).controller!;
      final secondController = tester.widget<ListView>(secondList).controller!;
      await tester.drag(firstList, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(firstController.offset, greaterThan(0));
      expect(secondController.offset, 0);
      expect(tester.getRect(header), headerBefore);
      await tester.drag(secondList, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(secondController.offset, greaterThan(0));
      final visibleCard = find
          .descendant(
            of: find.byKey(const ValueKey('kanban-column-issued')),
            matching: find.byType(ApiOrderCard),
          )
          .hitTestable()
          .first;
      final order = tester.widget<ApiOrderCard>(visibleCard).order;
      await tester.tap(visibleCard);
      expect(opened, order.id);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'empty mobile board keeps six columns, refreshes by pull and scrolls horizontally',
    (tester) async {
      viewport(tester, 320);
      var boardGets = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders/board') {
            boardGets++;
            return jsonResponse(boardJson());
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(host(MasterShell(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Наряды'), findsNWidgets(2));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('Фильтры'), findsOneWidget);
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      final before = boardGets;
      expect(find.byType(RefreshIndicator), findsOneWidget);
      for (final id in [
        'issued',
        'accepted',
        'inProgress',
        'queued',
        'completed',
        'overdue',
      ]) {
        expect(find.byKey(ValueKey('kanban-column-$id')), findsOneWidget);
      }
      await tester.drag(
        find.byKey(const PageStorageKey('kanban-orders-issued')),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();
      expect(boardGets, before + 1);
      final horizontal = find.byKey(const ValueKey('kanban-horizontal-scroll'));
      final controller = tester
          .widget<SingleChildScrollView>(horizontal)
          .controller!;
      await tester.drag(horizontal, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
