import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/l10n/backend_ui_labels.dart';
import 'package:mineral/l10n/ui_localization.dart';
import 'package:mineral/core/api/backend_document.dart';
import 'package:mineral/core/api/api_client.dart' as api;
import 'package:mineral/shared/widgets/backend_section.dart';
import 'helpers/localization_assertions.dart';

Widget host(Widget child) => MaterialApp(
  locale: const Locale('kk'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('visible static Russian labels do not bypass localization', () {
    final directLabels = RegExp(
      r'''(?:(?:Text|SelectableText)\(\s*|(?:tooltip|labelText|hintText|helperText):\s*)(['"])((?:(?!\1).)*?)\1''',
      dotAll: true,
    );
    final missing = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') ||
          file.path.contains(
            '${Platform.pathSeparator}l10n${Platform.pathSeparator}',
          )) {
        continue;
      }
      final source = file.readAsStringSync();
      for (final match in directLabels.allMatches(source)) {
        final label = match[2]!;
        if (RegExp('[А-Яа-яЁё]').hasMatch(label) &&
            !{'НарядAI', 'Русский / Қазақша'}.contains(label)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          missing.add('${file.path}:$line: $label');
        }
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  for (final language in ['ru', 'kk']) {
    testWidgets('API errors use $language and preserve unknown server text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: BackendError(
                message: backendError(
                  context,
                  const api.ApiException(
                    statusCode: 400,
                    message: 'Сервер вернул неверный формат данных',
                  ),
                ),
                onRetry: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.text(
          language == 'kk'
              ? 'Сервер деректерді қате пішімде қайтарды'
              : 'Сервер вернул неверный формат данных',
        ),
        findsOneWidget,
      );
      final context = tester.element(find.byType(Scaffold));
      expect(
        backendError(
          context,
          const api.ApiException(statusCode: 400, message: 'Ответ сервера XYZ'),
        ),
        'Ответ сервера XYZ',
      );
      expect(
        uiText(context, 'Это не ваш наряд'),
        strings(context).notYourOrderMessage,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all static legacy UI labels have Kazakh translations', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SizedBox()));
    final context = tester.element(find.byType(Scaffold));
    final allowed = <String>{
      for (final entry in russianMessages.entries)
        if (!entry.key.startsWith('@') &&
            entry.value == kazakhMessages[entry.key])
          entry.value as String,
      for (final entry in backendUiLabels.entries)
        if (entry.key == entry.value) entry.key,
    };
    final calls = RegExp(
      r'''(?:(?:uiText|_sectionTitle)\(\s*\w+,\s*|(?:PageHeading|SectionHeading|StatusTag|_sectionHeading|_smallHeading)\(\s*)(['"])((?:(?!\1).)*?)\1''',
      dotAll: true,
    );
    var checked = 0;
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') ||
          file.path.contains(
            '${Platform.pathSeparator}l10n${Platform.pathSeparator}',
          )) {
        continue;
      }
      for (final match in calls.allMatches(file.readAsStringSync())) {
        final source = match[2]!;
        if (source.contains(r'$') ||
            !RegExp('[А-Яа-яЁё]').hasMatch(source) ||
            allowed.contains(source)) {
          continue;
        }
        expect(
          uiText(context, source),
          isNot(source),
          reason: '${file.path}: $source',
        );
        checked++;
      }
    }
    expect(checked, greaterThan(100));
  });

  testWidgets('composed employee labels, offline messages and units localize', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SizedBox()));
    final context = tester.element(find.byType(Scaffold));
    final s = strings(context);
    expect(uiText(context, 'Настройки'), s.profileSettings);
    expect(uiText(context, 'Завершено'), s.completedShort);
    expect(
      uiText(context, 'В работе · 2 нар.'),
      '${s.working} · ${s.shortOrderCount('2')}',
    );
    expect(
      uiText(context, 'В очереди · 3 нар.'),
      '${s.queued} · ${s.shortOrderCount('3')}',
    );
    expect(uiText(context, '5 разряд'), s.employeeGradeOnly('5'));
    expect(
      uiText(context, 'Телефонда сақталды. Жіберуді күтіп тұр.'),
      s.offlineActionSaved,
    );
    expect(
      uiText(context, 'Действие не применено: Ответ сервера'),
      s.offlineActionNotApplied('Ответ сервера'),
    );
    expect(
      uiText(context, 'Сохранено на телефоне. Ожидает отправки.'),
      s.offlineActionSaved,
    );
    expect(uiText(context, 'Пользовательский текст'), 'Пользовательский текст');
    expect(
      uiText(context, 'С-02 · Загрязнение масла'),
      'С-02 · ${s.oilContaminationFault}',
    );
    expect(
      uiText(context, 'Масло индустриальное И-40А · л: 18.2'),
      '${s.industrialOilMaterial} · ${s.literUnit}: 18.2',
    );
    expect(
      uiText(context, 'Фильтр масляный · шт: 1.1'),
      '${s.oilFilterMaterial} · ${s.pieceUnit}: 1.1',
    );
  });

  testWidgets('report fields, enums and known catalog labels localize', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        BackendDocumentView(
          document: BackendDocument({
            'quality': 4.9,
            'onTimeRate': 1,
            'employeeStatus': 'AVAILABLE',
            'role': 'MASTER',
            'status': 'CLOSED',
            'equipment': 'Дробилка КМД-1750',
            'explanation': 'Ответ ИИ сервера',
          }),
        ),
      ),
    );
    expect(find.text('Сапа: 4.9'), findsOneWidget);
    expect(find.text('Қызметкер мәртебесі: Бос'), findsOneWidget);
    expect(find.text('Рөлі: Ауысым шебері'), findsOneWidget);
    expect(find.text('Мәртебе: Жабылды'), findsOneWidget);
    final s = strings(tester.element(find.byType(Scaffold)));
    expect(find.text('Жабдық: ${s.crusherEquipment}'), findsOneWidget);
    expect(find.text('Түсіндірме: Ответ ИИ сервера'), findsOneWidget);
    checkNoRussianLabels(tester);
  });
}
