import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/widgets/app_bottom_sheet.dart';

Widget host(VoidCallback Function(BuildContext) open) => MaterialApp(
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(onPressed: open(context), child: const Text('Open')),
    ),
  ),
);

void main() {
  testWidgets(
    'long content scrolls above keyboard while actions stay visible',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      bool? result;
      await tester.pumpWidget(
        host(
          (context) => () async {
            result = await showAppBottomSheet<bool>(
              context: context,
              builder: (context) => AppSheetContent(
                title: const Text('Title'),
                content: Column(
                  children: [for (var i = 0; i < 30; i++) Text('Row $i')],
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.getBottomLeft(find.text('Save')).dy, lessThan(544));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'date selection returns chosen day and cancellation returns null',
    (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        host(
          (context) => () async {
            result = await showAppDatePicker(
              context: context,
              initialDate: DateTime(2026, 10, 15),
              firstDate: DateTime(2026, 10, 1),
              lastDate: DateTime(2026, 10, 31),
              confirmText: 'Select',
              cancelText: 'Cancel',
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(DateTime(2026, 10, 20));
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 10, 20));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );

  testWidgets(
    'time sheet preserves minute precision and returns selected time',
    (tester) async {
      TimeOfDay? result;
      await tester.pumpWidget(
        host(
          (context) => () async {
            result = await showAppTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 10, minute: 7),
              confirmText: 'Select',
            );
          },
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final fields = find.byType(DropdownButtonFormField<int>);
      tester.widget<DropdownButtonFormField<int>>(fields.first).onChanged!(23);
      tester.widget<DropdownButtonFormField<int>>(fields.last).onChanged!(59);
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      expect(result, const TimeOfDay(hour: 23, minute: 59));
    },
  );

  testWidgets('range moves end forward when a later start is chosen', (
    tester,
  ) async {
    DateTimeRange? result;
    await tester.pumpWidget(
      host(
        (context) => () async {
          result = await showAppDateRangePicker(
            context: context,
            firstDate: DateTime(2026, 10, 1),
            lastDate: DateTime(2026, 10, 31),
            initialDateRange: DateTimeRange(
              start: DateTime(2026, 10, 10),
              end: DateTime(2026, 10, 12),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester
        .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
        .onDateChanged(DateTime(2026, 10, 20));
    await tester.pumpAndSettle();
    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(calendar.firstDate, DateTime(2026, 10, 20));
    calendar.onDateChanged(DateTime(2026, 10, 23));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(result!.start, DateTime(2026, 10, 20));
    expect(result!.end, DateTime(2026, 10, 23));
    expect(tester.takeException(), isNull);
  });
}
