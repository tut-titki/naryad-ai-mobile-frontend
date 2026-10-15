import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/orders/screens/orders_screen.dart';
import 'package:mineral/features/orders/widgets/master_completion_sheet.dart';
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

Map<String, dynamic> boardWith(String column, String status) {
  final board = boardJson();
  (board['columns'] as Map)[column] = [orderJson(status: status)];
  return board;
}

Future<TestGesture> holdCard(WidgetTester tester, String column) async {
  final card = find.byKey(ValueKey('kanban-drag-$column-773'));
  final gesture = await tester.startGesture(tester.getCenter(card));
  await tester.pump(const Duration(milliseconds: 650));
  return gesture;
}

Future<void> dropOn(
  WidgetTester tester,
  TestGesture gesture,
  String column,
) async {
  await gesture.moveTo(
    tester.getCenter(find.byKey(ValueKey('kanban-header-$column'))),
  );
  await tester.pump(const Duration(milliseconds: 40));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final transition in [
    ('issued', 'ISSUED', 'queued', 'QUEUED', 'QUEUE'),
    ('accepted', 'ACCEPTED', 'inProgress', 'IN_PROGRESS', 'START'),
    ('queued', 'QUEUED', 'inProgress', 'IN_PROGRESS', 'START'),
    ('overdue', 'PAUSED', 'inProgress', 'IN_PROGRESS', 'RESUME'),
  ]) {
    testWidgets(
      'drop ${transition.$2} into ${transition.$3} uses ${transition.$5}',
      (tester) async {
        viewport(tester, 1900);
        var status = transition.$2;
        var column = transition.$1;
        final actions = <Map<String, dynamic>>[];
        final api = testApi(
          handle: (request) async {
            if (request.url.path.endsWith('/action')) {
              actions.add(jsonDecode(request.body) as Map<String, dynamic>);
              status = transition.$4;
              column = transition.$3;
              return jsonResponse({'order': orderJson(status: status)});
            }
            if (request.url.path == '/api/work-orders/board') {
              return jsonResponse(boardWith(column, status));
            }
            return null;
          },
        );
        addTearDown(api.dispose);
        await tester.pumpWidget(
          host(
            Scaffold(
              body: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Канбан'));
        await tester.pumpAndSettle();
        await dropOn(
          tester,
          await holdCard(tester, transition.$1),
          transition.$3,
        );
        expect(actions.single['action'], transition.$5);
        expect(
          find.byKey(ValueKey('kanban-drag-${transition.$3}-773')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('kanban-drag-${transition.$1}-773')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'drop reviewed order back to work requests a reason and supports cancellation',
    (tester) async {
      viewport(tester, 1900);
      var status = 'AI_REVIEW';
      final actions = <Map<String, dynamic>>[];
      final api = testApi(
        handle: (request) async {
          if (request.url.path.endsWith('/action')) {
            actions.add(jsonDecode(request.body) as Map<String, dynamic>);
            status = 'REWORK';
            return jsonResponse({'order': orderJson(status: status)});
          }
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(
              boardWith(
                status == 'AI_REVIEW' ? 'completed' : 'inProgress',
                status,
              ),
            );
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      await dropOn(tester, await holdCard(tester, 'completed'), 'inProgress');
      expect(find.text('Что необходимо исправить'), findsOneWidget);
      expect(actions, isEmpty);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(actions, isEmpty);
      await dropOn(tester, await holdCard(tester, 'completed'), 'inProgress');
      await tester.tap(find.widgetWithText(FilledButton, 'На доработку'));
      await tester.pumpAndSettle();
      expect(find.text('Укажите причину'), findsOneWidget);
      expect(actions, isEmpty);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Что необходимо исправить'),
        'Check vibration',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'На доработку'));
      await tester.pumpAndSettle();
      expect(actions.single['action'], 'SEND_TO_REWORK');
      expect(actions.single['comment'], 'Check vibration');
      expect(
        find.byKey(const ValueKey('kanban-drag-inProgress-773')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'long press accepts an order through API and reloads server columns',
    (tester) async {
      viewport(tester, 1900);
      var status = 'ISSUED';
      final actions = <Map<String, dynamic>>[];
      var opens = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders/773/action') {
            actions.add(jsonDecode(request.body) as Map<String, dynamic>);
            status = 'ACCEPTED';
            return jsonResponse({
              'order': orderJson(status: status),
              'assessment': null,
            });
          }
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(
              boardWith(status == 'ISSUED' ? 'issued' : 'accepted', status),
            );
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
              onOrder: (_) => opens++,
              onCreate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      final gesture = await holdCard(tester, 'issued');
      expect(actions, isEmpty);
      expect(opens, 0);
      await dropOn(tester, gesture, 'accepted');
      expect(actions.single['action'], 'ACCEPT');
      expect(actions.single['clientActionId'], isNotEmpty);
      expect(
        find.byKey(const ValueKey('kanban-drag-issued-773')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('kanban-drag-accepted-773')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('kanban-drag-accepted-773')));
      expect(opens, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'failed moves keep the card, show server error and reuse action ID on retry',
    (tester) async {
      viewport(tester, 1900);
      final actions = <Map<String, dynamic>>[];
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders/773/action') {
            actions.add(jsonDecode(request.body) as Map<String, dynamic>);
            return jsonResponse({
              'error': 'Сервис временно недоступен',
            }, status: 503);
          }
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(boardWith('issued', 'ISSUED'));
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      await dropOn(tester, await holdCard(tester, 'issued'), 'accepted');
      expect(find.text('Сервис временно недоступен'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('kanban-drag-issued-773')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kanban-drag-accepted-773')),
        findsNothing,
      );
      await dropOn(tester, await holdCard(tester, 'issued'), 'accepted');
      expect(actions.length, 2);
      expect(actions.last['clientActionId'], actions.first['clientActionId']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'same column and derived overdue column do not change the order',
    (tester) async {
      viewport(tester, 1900);
      var actions = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path.endsWith('/action')) actions++;
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(boardWith('issued', 'ISSUED'));
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      for (final target in ['issued', 'overdue', 'completed', 'inProgress']) {
        await dropOn(tester, await holdCard(tester, 'issued'), target);
      }
      expect(actions, 0);
      expect(
        find.byKey(const ValueKey('kanban-drag-issued-773')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'dragging to the mobile edge scrolls to hidden columns and stops on release',
    (tester) async {
      viewport(tester, 320);
      final api = testApi(
        handle: (request) async => request.url.path == '/api/work-orders/board'
            ? jsonResponse(boardWith('issued', 'ISSUED'))
            : null,
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      final controller = tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('kanban-horizontal-scroll')),
          )
          .controller!;
      final gesture = await holdCard(tester, 'issued');
      await gesture.moveTo(const Offset(296, 400));
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.offset, greaterThan(200));
      await gesture.moveTo(const Offset(160, 400));
      await gesture.up();
      await tester.pumpAndSettle();
      final stopped = controller.offset;
      await tester.pump(const Duration(seconds: 1));
      expect(controller.offset, stopped);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'drop into completed requires a valid execution report and sends materials',
    (tester) async {
      viewport(tester, 1900);
      var status = 'IN_PROGRESS';
      final actions = <Map<String, dynamic>>[];
      final api = testApi(
        handle: (request) async {
          if (request.url.path.endsWith('/action')) {
            actions.add(jsonDecode(request.body) as Map<String, dynamic>);
            status = 'AI_REVIEW';
            return jsonResponse({
              'order': orderJson(status: status),
              'assessment': null,
            });
          }
          if (request.url.path == '/api/references/fault-codes') {
            return jsonResponse([
              {'id': 3, 'code': 'F-3', 'name': 'Fault'},
            ]);
          }
          if (request.url.path == '/api/references/materials') {
            return jsonResponse([
              {'id': 8, 'name': 'Material', 'unit': 'kg'},
            ]);
          }
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(
              boardWith(
                status == 'IN_PROGRESS' ? 'inProgress' : 'completed',
                status,
              ),
            );
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      await dropOn(tester, await holdCard(tester, 'inProgress'), 'completed');
      expect(find.byType(MasterCompletionSheet), findsOneWidget);
      expect(actions, isEmpty);
      await tester.tap(
        find.widgetWithText(FilledButton, 'Отправить на проверку'),
      );
      await tester.pumpAndSettle();
      expect(actions, isEmpty);
      expect(find.text('Опишите выполненные работы'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('kanban-completion-work')),
        'Replaced seal and checked operation',
      );
      await tester.tap(find.byKey(const ValueKey('kanban-completion-fault')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('F-3 · Fault').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить материал'));
      await tester.pumpAndSettle();
      final materialRow = find.widgetWithText(
        DropdownButtonFormField<int>,
        'Материал',
      );
      await tester.tap(materialRow);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Material · kg').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Количество'),
        '1,5',
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Отправить на проверку'),
      );
      await tester.pumpAndSettle();
      expect(actions.single['action'], 'COMPLETE');
      expect(
        actions.single['completionText'],
        'Replaced seal and checked operation',
      );
      expect(actions.single['faultCodeId'], 3);
      expect(actions.single['materials'], [
        {'materialId': 8, 'quantity': 1.5},
      ]);
      expect(find.byType(MasterCompletionSheet), findsNothing);
      expect(
        find.byKey(const ValueKey('kanban-drag-completed-773')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'shift create button floats above navigation, stays fixed and opens creation',
    (tester) async {
      viewport(tester, 390);
      final api = createFormApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(host(MasterShell(api: api)));
      await tester.pumpAndSettle();
      final fab = find.byKey(const ValueKey('master-create-order-fab'));
      final rect = tester.getRect(fab);
      expect(
        rect.bottom,
        lessThan(tester.getRect(find.byType(NavigationBar)).top),
      );
      expect(
        tester.widget<FloatingActionButton>(fab).backgroundColor,
        const Color(0xFF01408B),
      );
      expect(find.widgetWithText(FilledButton, 'Создать наряд'), findsNothing);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(fab), rect);
      await tester.tap(fab);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(CreateOrderScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(CreateOrderScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(fab, findsNothing);
      final tabs = find.byType(TabBar);
      expect(
        find.ancestor(of: tabs, matching: find.byType(AppBar)),
        findsOneWidget,
      );
      final tabBar = tester.widget<TabBar>(tabs);
      expect(tabBar.labelColor, Colors.white);
      expect(tabBar.unselectedLabelColor, Colors.white);
      expect(tabBar.indicatorColor, Colors.white);
      expect(
        tester.getRect(tabs).bottom,
        tester.getRect(find.byType(AppBar)).bottom,
      );
      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('kanban-horizontal-scroll')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
