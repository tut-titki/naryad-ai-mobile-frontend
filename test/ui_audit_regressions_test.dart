import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/api/backend_document.dart';
import 'package:mineral/features/orders/data/references_api.dart';
import 'package:mineral/features/executor/screens/executor_screen.dart';
import 'package:mineral/shared/data/demo_store.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/shared/widgets/backend_section.dart';
import 'package:mineral/l10n/app_localizations.dart';

Widget host(String language, Widget child) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  test('current work overrides available or queued; off-shift still wins', () {
    for (final status in ['AVAILABLE', 'QUEUED']) {
      final json = <String, dynamic>{
        'id': 1,
        'fullName': 'Worker',
        'isOnShift': true,
        'employeeStatus': status,
        'currentOrder': {
          'id': 1551,
          'number': 'Н-00513',
          'status': 'IN_PROGRESS',
          'priority': 'NORMAL',
          'deadline': '2026-10-15T12:00:00Z',
          'equipment': {'name': 'Pump'},
        },
      };
      expect(
        ExecutorReference.fromJson(json).assignmentStatusLabel,
        'В работе',
      );
      expect(
        ExecutorReference.fromJson({
          ...json,
          'isOnShift': false,
        }).assignmentStatusLabel,
        'Не на смене',
      );
      expect(
        ExecutorReference.fromJson({
          ...json,
          'currentOrder': null,
        }).assignmentStatusLabel,
        status == 'AVAILABLE' ? 'Свободен' : 'В очереди',
      );
    }
  });

  for (final language in ['ru', 'kk']) {
    testWidgets('report translates reasons and dates in $language', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          language,
          const BackendDocumentView(
            document: BackendDocument({
              'pauseReason': 'Reason A',
              'rejectionReason': 'Reason B',
              'updatedAt': '2026-10-15T06:30:00Z',
              'acceptedAt': '2026-10-15T05:00:00Z',
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in [
        'pauseReason',
        'rejectionReason',
        'updatedAt',
        'acceptedAt',
      ]) {
        expect(find.textContaining(key), findsNothing);
      }
      expect(
        find.textContaining(
          language == 'ru'
              ? 'Причина приостановки: Reason A'
              : 'Уақытша тоқтату себебі: Reason A',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('11:30 15.10.2026'), findsOneWidget);
      expect(find.textContaining('10:00 15.10.2026'), findsOneWidget);
    });

    testWidgets('overdue card has one minutes suffix in $language', (
      tester,
    ) async {
      final store = DemoStore();
      addTearDown(store.dispose);
      final order = store.assignedTo(1).first;
      order.status = OrderStatus.working;
      order.deadline = DateTime.now().subtract(
        const Duration(days: 2, hours: 3, minutes: 7),
      );
      await tester.pumpWidget(
        host(
          language,
          ExecutorScreen(store: store, employeeId: 1, refreshOnOpen: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('мин мин'), findsNothing);
      expect(
        find.textContaining(
          language == 'ru' ? 'Просрочен на 2 д 3 ч' : 'Мерзімі 2 күн 3 сағ',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
