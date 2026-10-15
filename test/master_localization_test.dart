import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'helpers/backend_api_fixture.dart';
import 'package:flutter/material.dart';
import 'package:mineral/features/assistant/screens/ai_screen.dart';
import 'helpers/localization_assertions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/l10n/ui_localization.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/core/theme/app_theme.dart';

class LocalizationPhotoPicker extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

void main() {
  for (final language in ['ru', 'kk']) {
    testWidgets(
      'AI control headings and assistant labels localize in $language',
      (tester) async {
        final api = testApi();
        addTearDown(api.dispose);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AiScreen(api: api, onOrder: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(AiScreen));
        for (final label in [
          'ИИ-контроль',
          'Контроль нарядов',
          'Мониторинг оборудования',
          'Цифровой помощник',
          'Задайте вопрос по производству',
        ]) {
          final translated = uiText(context, label);
          if (language == 'kk') expect(translated, isNot(label));
          expect(find.text(translated), findsOneWidget);
        }
        if (language == 'kk') checkNoRussianLabels(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('all ARB-backed labels and composed values translate to Kazakh', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('kk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    for (final entry in russianMessages.entries.where(
      (e) => !e.key.startsWith('@'),
    )) {
      final source = entry.value as String;
      if (source.contains('{')) continue;
      // Direct-key widgets need no adapter; audit every mapped source label.
      final mapped = uiText(context, source);
      if (mapped != source || source == kazakhMessages[entry.key]) {
        expect(mapped, kazakhMessages[entry.key], reason: entry.key);
      }
    }
    final s = strings(context);
    expect(uiText(context, 'ACCEPTED'), s.aiVerdictAcceptedLabel);
    expect(uiText(context, 'ACCEPTED_WITH_COMMENTS'), s.aiVerdictCommentsLabel);
    expect(uiText(context, 'REWORK_REQUIRED'), s.aiVerdictReworkLabel);
    expect(
      uiText(context, 'выполняет наряд №Н-00147, в очереди 1'),
      s.executorCurrentOrderQueue('Н-00147', '1'),
    );
    expect(uiText(context, 'в очереди 2 наряда'), s.executorQueuedOrders('2'));
    expect(uiText(context, 'Бригада №1'), s.brigadeNumber('1'));
    expect(
      uiText(context, 'Сварщик · 5 разряд'),
      s.employeeGrade(s.welderSpecialty, '5'),
    );
    expect(
      uiText(context, 'Дробилка КМД-1750 · Дробление'),
      '${s.crusherEquipment} · ${s.crushingArea}',
    );
    expect(uiText(context, 'Подшипник · шт: 2.0'), '${s.bearingMaterial}: 2.0');
    expect(
      uiText(
        context,
        'Демо-ответ: здесь появятся рекомендации по запросу «Кто свободен?». Для анализа необходимо подключить backend и ИИ.',
      ),
      s.masterDemoAnswer('Кто свободен?'),
    );
    expect(uiText(context, 'Пользовательский текст'), 'Пользовательский текст');
  });

  testWidgets(
    'populated creation form, catalogs and live language switch localize',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = testApi(
        handle: (request) async {
          return switch (request.url.path) {
            '/api/references/areas' => jsonResponse([
              {'id': 1, 'name': 'Дробление'},
            ]),
            '/api/references/equipment' => jsonResponse([
              {
                'id': 2,
                'name': 'Дробилка КМД-1750',
                'areaId': 1,
                'inventoryNumber': 'Д-2',
              },
            ]),
            '/api/references/executors' => jsonResponse([
              {
                ...executorJson(),
                'specialty': 'Сварщик',
                'employeeStatus': 'BUSY',
              },
            ]),
            '/api/references/fault-codes' => jsonResponse([
              {'id': 1, 'code': 'М-02', 'name': 'Подшипник'},
            ]),
            '/api/references/normatives' => jsonResponse([
              {'id': 1, 'name': 'Замена подшипника привода', 'hours': '2'},
            ]),
            _ => null,
          };
        },
      );
      addTearDown(api.dispose);
      final locale = ValueNotifier(const Locale('kk'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (_, language, _) => MaterialApp(
            locale: language,
            theme: buildAppTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CreateOrderScreen(
              api: api,
              photoPicker: LocalizationPhotoPicker(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var scroll = 0; scroll < 5; scroll++) {
        checkNoRussianLabels(tester);
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -350),
        );
        await tester.pumpAndSettle();
      }
      locale.value = const Locale('ru');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('issue-order')), findsOneWidget);
      locale.value = const Locale('kk');
      await tester.pumpAndSettle();
      checkNoRussianLabels(tester);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1400.0]) {
    testWidgets('backend master pages localize at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = testApi();
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('kk'),
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MasterShell(api: api),
        ),
      );
      await tester.pumpAndSettle();
      for (var index = 0; index < 5; index++) {
        final navigation = width < 1000
            ? find.byType(NavigationDestination).at(index)
            : find.byType(ListTile).at(index);
        await tester.tap(navigation);
        await tester.pumpAndSettle();
        checkNoRussianLabels(tester);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
