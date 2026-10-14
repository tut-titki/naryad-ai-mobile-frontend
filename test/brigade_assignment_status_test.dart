import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/models/models.dart';

import 'helpers/backend_api_fixture.dart';

class NoPhotos extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

void main() {
  for (final language in ['ru', 'kk']) {
    testWidgets('brigade availability and refresh in $language', (
      tester,
    ) async {
      var firstHasQueue = false;
      Map<String, Object> executor(
        int id,
        String status, {
        bool onShift = true,
        int queue = 0,
        int? brigadeId,
      }) => {
        'id': id,
        'fullName': 'Worker $id',
        'employeeStatus': status,
        'isOnShift': onShift,
        'queue': queue,
        'brigadeId': ?brigadeId,
      };
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/references/executors') {
            return jsonResponse([
              executor(1, 'AVAILABLE', queue: firstHasQueue ? 1 : 0),
              executor(2, 'BUSY', onShift: false),
              executor(3, 'AVAILABLE'),
              executor(4, 'QUEUED', queue: 2),
              executor(5, 'BUSY', onShift: false),
              executor(6, 'AVAILABLE', brigadeId: 4),
              executor(7, 'UNKNOWN'),
            ]);
          }
          if (request.url.path == '/api/references/brigades') {
            return jsonResponse([
              for (final group in [
                (1, 'Brigade A', [1, 2]),
                (2, 'Brigade B', [3, 4]),
                (3, 'Brigade C', [5]),
                (4, 'Brigade D', <int>[]),
                (5, 'Brigade E', [7]),
              ])
                {
                  'id': group.$1,
                  'name': group.$2,
                  'members': [
                    for (final id in group.$3)
                      {'id': id, 'fullName': 'Worker $id'},
                  ],
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
          home: CreateOrderScreen(
            api: api,
            draftStorage: MemoryReferenceStorage(),
            photoPicker: NoPhotos(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('order-advanced')));
      await tester.tap(find.byKey(const ValueKey('order-advanced')));
      await tester.pumpAndSettle();
      final mode = find
          .ancestor(
            of: find.text('Бригада'),
            matching: find.byType(SegmentedButton<bool>),
          )
          .first;
      await tester.ensureVisible(mode);
      await tester.tap(
        find.descendant(of: mode, matching: find.text('Бригада')),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('brigade-null'));
      await tester.ensureVisible(field);
      final dropdown = tester.widget<DropdownButton<int>>(
        find.descendant(of: field, matching: find.byType(DropdownButton<int>)),
      );
      expect(dropdown.items!.map((item) => item.enabled), [
        true,
        true,
        false,
        true,
        true,
      ]);
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(find.text(language == 'ru' ? 'Свободна' : 'Бос'), findsWidgets);
      expect(find.text(language == 'ru' ? 'Занята' : 'Бос емес'), findsWidgets);
      expect(
        find.text(language == 'ru' ? 'Не на смене' : 'Ауысымда емес'),
        findsWidgets,
      );
      await tester.tap(find.text('Brigade A').last);
      await tester.pumpAndSettle();
      final selected = find.byKey(const ValueKey('brigade-1'));
      expect(
        find.descendant(
          of: selected,
          matching: find.text(language == 'ru' ? 'Свободна' : 'Бос'),
        ),
        findsOneWidget,
      );
      firstHasQueue = true;
      final refresh = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();
      await refresh;
      expect(
        find.descendant(
          of: selected,
          matching: find.text(language == 'ru' ? 'Занята' : 'Бос емес'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
