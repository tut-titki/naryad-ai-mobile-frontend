import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/reports/widgets/report_content.dart';
import 'package:mineral/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'material report localizes known catalog labels and keeps unknown data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('kk'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ReportContent(
                report: 'materials',
                data: [
                  {
                    'material': 'Масло индустриальное И-40А',
                    'unit': 'л',
                    'quantity': 2,
                    'group': {'name': 'Участок с пользовательским названием'},
                  },
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final s = AppLocalizations.of(tester.element(find.byType(ReportContent)));
      expect(find.text(s.industrialOilMaterial), findsOneWidget);
      expect(find.text('2 ${s.literUnit}'), findsOneWidget);
      expect(find.text('Участок с пользовательским названием'), findsOneWidget);
      expect(find.text('Масло индустриальное И-40А'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final report in [
    'shift',
    'materials',
    'downtime',
    'ratings',
    'brigade-ratings',
  ]) {
    testWidgets('$report explains missing and nested empty data', (
      tester,
    ) async {
      for (final data in [
        null,
        [],
        {},
        {
          'items': [],
          'totals': {'minutes': null},
          'aiSummary': '   ',
        },
        [
          {'id': 7},
        ],
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ReportContent(report: report, data: data),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Нет данных за выбранный период'), findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('empty sections disappear while zero and false stay visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ReportContent(
              report: 'shift',
              data: {
                'closed': 0,
                'workload': {},
                'aiSummary': '   ',
                'downtime': {'minutes': null},
                'load': [
                  {
                    'id': 7,
                    'fullName': 'Employee',
                    'assigned': 1,
                    'completed': 0,
                    'isOnShift': false,
                  },
                ],
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Команда на смене'), findsNothing);
    expect(find.text('AI-сводка'), findsNothing);
    expect(find.text('Простои за смену'), findsNothing);
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.text('Загрузка сотрудников'));
    await tester.pumpAndSettle();
    expect(find.text('Нет'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ru', 'kk']) {
    for (final report in ['materials', 'downtime']) {
      testWidgets(
        '$report preserves API values on a narrow screen in $language',
        (tester) async {
          tester.view.physicalSize = const Size(360, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final Object data = report == 'materials'
              ? [
                  {
                    'materialId': 99,
                    'material':
                        'Material with a long inventory name for mobile display',
                    'group': {
                      'id': 45,
                      'name': 'Production area with a long name',
                    },
                    'unit': 'kg',
                    'quantity': 12.5,
                    'count': 4,
                    'normQuantity': 10,
                    'deviationPercent': 25,
                    'overNormCount': 2,
                    'overNormOrders': [
                      {'id': 774, 'number': 'N-774'},
                    ],
                  },
                ]
              : {
                  'totals': {
                    'minutes': 180,
                    'plannedMinutes': 60,
                    'unplannedMinutes': 120,
                    'plannedShare': 0.333,
                    'unplannedShare': 0.667,
                    'ongoing': 1,
                  },
                  'byEquipment': [
                    {
                      'equipmentId': 99,
                      'equipment': 'Equipment with a long name',
                      'area': {
                        'id': 45,
                        'name': 'Production area with a long name',
                      },
                      'minutes': 180,
                      'count': 3,
                      'plannedMinutes': 60,
                      'unplannedMinutes': 120,
                      'ongoing': 1,
                      'byFaultCode': [
                        {
                          'code': 'M-04',
                          'name': 'Fault',
                          'minutes': 180,
                          'count': 3,
                        },
                      ],
                    },
                  ],
                  'items': [
                    {'workOrderId': 774, 'number': 'N-774', 'minutes': 180},
                  ],
                };
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(1.4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReportContent(report: report, data: data),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Production area with a long name'), findsOneWidget);
          if (report == 'materials') {
            expect(find.text('12.5 kg'), findsOneWidget);
            expect(find.text('25%'), findsOneWidget);
            expect(find.text('10'), findsOneWidget);
          } else {
            expect(find.text('180'), findsNWidgets(2));
            expect(find.text('0.333'), findsOneWidget);
            final chart = tester.widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            );
            expect(chart.value, closeTo(1 / 3, .0001));
          }
          expect(find.textContaining(RegExp(r'^ID(?:\s|:)')), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
