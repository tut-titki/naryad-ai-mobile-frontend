import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/api/backend_document.dart';
import 'package:mineral/features/master/screens/dashboard_screen.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/master/widgets/dashboard_data.dart';
import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'helpers/backend_api_fixture.dart';

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  for (final width in [320.0, 390.0, 1400.0]) {
    testWidgets(
      'dashboard counters adapt to width and heading stays in appbar at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = testApi(
          handle: (request) async =>
              request.url.path == '/api/work-orders/board'
              ? jsonResponse(
                  boardJson()
                    ..['counters'] = {
                      'issued': 14,
                      'completed': 9,
                      'overdue': 2,
                      'equipmentInDowntime': 1,
                    },
                )
              : null,
        );
        addTearDown(api.dispose);
        await tester.pumpWidget(host(MasterShell(api: api)));
        await tester.pumpAndSettle();
        expect(
          find.text('Обзор смены'),
          width < 1000 ? findsOneWidget : findsNWidgets(2),
        );
        expect(find.text('Текущие показатели и наряды смены'), findsOneWidget);
        if (width < 1000) {
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Обзор смены'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.byType(Image),
            ),
            findsNothing,
          );
        }
        final counters = find.byKey(const ValueKey('shift-counters'));
        final points = [
          for (final text in ['14', '9', '2', '1'])
            tester.getCenter(
              find.descendant(of: counters, matching: find.text(text)),
            ),
        ];
        expect(points.map((p) => p.dy).toSet().length, width < 600 ? 2 : 1);
        expect(points[0].dy, points[1].dy);
        if (width < 600) {
          expect(points[2].dy, greaterThan(points[0].dy));
        }
        expect(
          tester.getSize(counters).height,
          lessThanOrEqualTo(width < 600 ? 220 : 110),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('top lists show only names, failures, scores and closed counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Column(
            children: [
              EquipmentFailuresList(
                document: BackendDocument.fromJson([
                  {
                    'equipmentId': 99,
                    'name': 'Насос Н-12',
                    '_count': 6,
                    'unexpected': 'HIDDEN EQUIPMENT DATA',
                  },
                ]),
              ),
              ExecutorRankingList(
                document: BackendDocument.fromJson([
                  {
                    'id': 88,
                    'fullName': 'Ахметов Ерлан',
                    'score': 4.81234,
                    'closed': 12,
                    'unexpected': 'HIDDEN EXECUTOR DATA',
                  },
                ]),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Насос Н-12'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Ахметов Ерлан'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('HIDDEN'), findsNothing);
    expect(find.text('99'), findsNothing);
    expect(find.text('88'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('attention contains at most three orders ordered by urgency', (
    tester,
  ) async {
    final orders = [
      orderJson(id: 1, status: 'AI_REVIEW'),
      orderJson(id: 2)..['deadline'] = '2020-01-01T00:00:00Z',
      orderJson(id: 3)
        ..['deadline'] = '2020-01-02T00:00:00Z'
        ..['priority'] = 'HIGH',
      orderJson(id: 4)..['priority'] = 'EMERGENCY',
      orderJson(id: 5)
        ..['priority'] = 'EMERGENCY'
        ..['deadline'] = '2020-01-03T00:00:00Z',
    ];
    final api = testApi(
      handle: (request) async =>
          request.url.path == '/api/work-orders' ? jsonResponse(orders) : null,
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      host(
        Scaffold(
          body: SingleChildScrollView(
            child: DashboardScreen(api: api, onOrder: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cards = tester
        .widgetList<ApiOrderCard>(find.byType(ApiOrderCard))
        .toList();
    expect(cards.map((card) => card.order.id), [5, 4, 3]);
    expect(cards.length, 3);
    expect(tester.takeException(), isNull);
    expect(WorkOrderApiModel.fromJson(orders[0]).waitingForMasterReview, true);
  });
}
