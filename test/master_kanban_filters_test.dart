import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/features/orders/screens/orders_screen.dart';
import 'helpers/backend_api_fixture.dart';
import 'master_kanban_layout_test.dart' show host, viewport;

void main() {
  for (final filter in ['status', 'priority', 'overdue', 'search']) {
    testWidgets('list and kanban apply $filter to unfiltered responses', (
      tester,
    ) async {
      viewport(tester, 1900);
      final other = {...orderJson(id: 1), 'description': 'Other task'};
      final matching = {
        ...orderJson(id: 2, status: 'IN_PROGRESS'),
        'priority': 'HIGH',
        'description': 'Needle task',
        'deadline': DateTime.now()
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
      };
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders') {
            return jsonResponse([other, matching]);
          }
          if (request.url.path == '/api/work-orders/board') {
            return jsonResponse(
              boardJson(issued: [other], inProgress: [matching]),
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

      if (filter == 'search') {
        await tester.enterText(find.byType(TextField).first, 'needle');
      } else {
        await tester.tap(find.byTooltip('Фильтры'));
        await tester.pumpAndSettle();
        if (filter == 'status') {
          await tester.tap(
            find.byType(DropdownButtonFormField<WorkOrderStatus?>),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('В работе').last);
        } else if (filter == 'priority') {
          await tester.tap(
            find.byType(DropdownButtonFormField<WorkOrderPriority?>),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Высокий').last);
        } else {
          await tester.ensureVisible(find.text('Только просроченные'));
          await tester.tap(find.text('Только просроченные'));
        }
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Применить'));
        await tester.tap(find.text('Применить'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Other task'), findsNothing);
      expect(find.text('Needle task'), findsOneWidget);

      await tester.tap(find.text('Канбан'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('kanban-drag-issued-1')), findsNothing);
      expect(
        find.byKey(const ValueKey('kanban-drag-inProgress-2')),
        findsOneWidget,
      );

      // Reset restores the other order without switching presentation.
      if (filter == 'search') {
        await tester.enterText(find.byType(TextField).first, '');
      } else {
        await tester.tap(find.byTooltip('Фильтры'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Сбросить'));
        await tester.tap(find.text('Сбросить'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Применить'));
        await tester.tap(find.text('Применить'));
      }
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('kanban-drag-issued-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kanban-drag-inProgress-2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
