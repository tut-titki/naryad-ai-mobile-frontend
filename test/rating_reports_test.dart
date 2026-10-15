import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/reports/screens/reports_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/widgets/backend_refresh_view.dart';

import 'helpers/backend_api_fixture.dart';

void main() {
  for (final language in ['ru', 'kk']) {
    for (final brigades in [false, true]) {
      testWidgets(
        'filtered chart and mobile components for brigades=$brigades in $language',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var score = 79.4;
          final queries = <Map<String, String>>[];
          final reportType = brigades ? 'brigade-ratings' : 'ratings';
          final api = testApi(
            handle: (request) async {
              if (request.url.path == '/api/references/brigades') {
                return jsonResponse([
                  {'id': 1, 'name': 'Crew', 'members': []},
                ]);
              }
              if (request.url.path == '/api/reports/$reportType') {
                queries.add(request.url.queryParameters);
                return jsonResponse([
                  {
                    'id': 97,
                    brigades ? 'name' : 'fullName': 'Second',
                    'score': 0,
                  },
                  {
                    'id': 123456,
                    brigades ? 'name' : 'fullName': 'First with a longer name',
                    'score': score,
                    'points': {
                      'quality': 40.5,
                      'onTime': 20,
                      'noReturns': 13.5,
                      'volume': 5,
                      'complexity': 2.4,
                      'rejects': -2,
                    },
                    'explanation': 'Explanation from the server',
                  },
                ]);
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
          final s = AppLocalizations.of(
            tester.element(find.byType(ReportsScreen)),
          );
          await tester.tap(
            find.text(language == 'ru' ? 'Фильтры' : 'Сүзгілер'),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.weekPeriod));
          final type = find.byType(DropdownButtonFormField<String>);
          await tester.ensureVisible(type);
          await tester.tap(type);
          await tester.pumpAndSettle();
          final typeLabel = brigades
              ? (language == 'ru' ? 'Рейтинг бригад' : 'Бригадалар рейтингі')
              : (language == 'ru'
                    ? 'Рейтинг исполнителей'
                    : 'Орындаушылар рейтингі');
          await tester.tap(find.text(typeLabel).last);
          await tester.pumpAndSettle();
          final brigadeFilter = find.byKey(
            const ValueKey('scope-brigadeId-null'),
          );
          await tester.ensureVisible(brigadeFilter);
          await tester.tap(brigadeFilter);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Crew').last);
          await tester.pumpAndSettle();
          final apply = find.text(language == 'ru' ? 'Применить' : 'Қолдану');
          await tester.ensureVisible(apply);
          await tester.tap(apply);
          await tester.pumpAndSettle();
          expect(queries.last, {'period': 'week', 'brigadeId': '1'});
          final first = find.byKey(const ValueKey('rating-components-0'));
          final second = find.byKey(const ValueKey('rating-components-1'));
          expect(first, findsOneWidget);
          expect(second, findsOneWidget);
          expect(
            find.descendant(
              of: first,
              matching: find.text('First with a longer name'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: first, matching: find.text('79.4/100')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: first, matching: find.text('40.5')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: first, matching: find.text('-2')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: second, matching: find.text('—')),
            findsNWidgets(6),
          );
          expect(find.text('123456'), findsNothing);
          expect(
            tester
                .widget<FractionallySizedBox>(
                  find.byKey(const ValueKey('rating-bar-0')),
                )
                .widthFactor,
            closeTo(.794, .00001),
          );
          expect(
            find.byKey(const ValueKey('rating-table-scroll')),
            findsNothing,
          );
          score = 65.2;
          final refresh = tester
              .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
              .show();
          await tester.pumpAndSettle();
          await refresh;
          expect(queries.last, {'period': 'week', 'brigadeId': '1'});
          expect(queries, hasLength(2));
          expect(
            find.descendant(of: first, matching: find.text('65.2/100')),
            findsOneWidget,
          );
          expect(
            tester
                .widget<FractionallySizedBox>(
                  find.byKey(const ValueKey('rating-bar-0')),
                )
                .widthFactor,
            closeTo(.652, .00001),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
