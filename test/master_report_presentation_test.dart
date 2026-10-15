import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/reports/screens/reports_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/widgets/backend_refresh_view.dart';

import 'helpers/backend_api_fixture.dart';

void main() {
  for (final language in ['ru', 'kk']) {
    testWidgets(
      'report includes participating employees, formats time and hides nested IDs in $language',
      (tester) async {
        final api = testApi(
          handle: (request) async {
            if (request.url.path == '/api/reports/shift') {
              return jsonResponse({
                'from': '2026-10-16T14:40:00Z',
                'to': '2026-10-17T18:59:59.999Z',
                'issued': 2,
                'completed': 1,
                'overdue': 0,
                'load': [
                  {
                    'id': 7,
                    'fullName': 'Assigned employee',
                    'assigned': 2,
                    'completed': 0,
                    'activeNow': 0,
                  },
                  {
                    'id': 8,
                    'fullName': 'Completed employee',
                    'assigned': 0,
                    'completed': 1,
                    'isOnShift': false,
                  },
                  {
                    'id': 9,
                    'fullName': 'Unrelated employee',
                    'assigned': 0,
                    'completed': 0,
                    'activeNow': 4,
                  },
                ],
                'orders': [
                  {
                    'id': 773,
                    'number': 'N-773',
                    'assigneeId': 7,
                    'createdAt': '2026-10-16T19:40:00+05:00',
                    'equipment': {'id': 2, 'name': 'Pump', 'areaId': 1},
                  },
                ],
              });
            }
            return null;
          },
        );
        addTearDown(api.dispose);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BackendRefreshView(child: ReportsScreen(api: api)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('19:40 16.10.2026'), findsOneWidget);
        expect(find.textContaining('23:59 17.10.2026'), findsOneWidget);
        final load = find.text(
          language == 'ru'
              ? 'Загрузка сотрудников'
              : 'Қызметкерлердің жүктемесі',
        );
        await tester.ensureVisible(load);
        await tester.tap(load);
        await tester.pumpAndSettle();
        expect(find.textContaining('Assigned employee'), findsOneWidget);
        expect(find.textContaining('Completed employee'), findsOneWidget);
        expect(find.textContaining('Unrelated employee'), findsNothing);
        final orders = find.text(language == 'ru' ? 'Наряды' : 'Нарядтар');
        await tester.ensureVisible(orders);
        await tester.tap(orders);
        await tester.pumpAndSettle();
        expect(find.textContaining('N-773'), findsOneWidget);
        expect(find.textContaining('19:40 16.10.2026'), findsNWidgets(2));
        final equipment = find.text(
          language == 'ru' ? 'Оборудование' : 'Жабдық',
        );
        await tester.ensureVisible(equipment);
        await tester.tap(equipment);
        await tester.pumpAndSettle();
        expect(find.textContaining('Pump'), findsOneWidget);
        expect(find.textContaining(RegExp(r'^ID(?:\s|:)')), findsNothing);
        expect(find.textContaining('2026-10-16T'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
