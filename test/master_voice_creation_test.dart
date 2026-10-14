import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:record/record.dart';

import 'helpers/backend_api_fixture.dart';
import 'helpers/recording_fixture.dart';

class _NoPhotos extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

void main() {
  late TestRecorderPlatform platform;
  setUp(() {
    final original = RecordPlatform.instance;
    platform = TestRecorderPlatform();
    RecordPlatform.instance = platform;
    addTearDown(() => RecordPlatform.instance = original);
  });

  Future<void> tapVoice(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.runAsync(() async {
      await tester.tap(find.text(label));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  Future<void> mount(
    WidgetTester tester,
    http.Response response, {
    String language = 'ru',
  }) async {
    final api = testApi(
      handle: (request) async {
        if (request.url.path != '/api/ai/transcribe') return null;
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer master-jwt');
        final body = latin1.decode(request.bodyBytes);
        expect(body, contains('name="audio"'));
        expect(body, contains('RIFF'));
        return response;
      },
    )..client.setAccessToken('master-jwt');
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CreateOrderScreen(
          api: api,
          draftStorage: MemoryReferenceStorage(),
          photoPicker: _NoPhotos(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await platform.states.close();
      api.dispose();
    });
  }

  final field = find.byKey(const ValueKey('order-description'));
  for (final response in <String, http.Response>{
    'plain text': http.Response.bytes(
      utf8.encode('  Заменить подшипник.  '),
      200,
      headers: {'content-type': 'text/plain; charset=utf-8'},
    ),
    'wrapped JSON': jsonResponse({
      'result': {'text': '  Заменить подшипник.  '},
    }),
    'documented JSON with wrong HTML MIME type': http.Response.bytes(
      utf8.encode(jsonEncode({'text': '  Заменить подшипник.  '})),
      200,
      headers: {'content-type': 'text/html; charset=utf-8'},
    ),
  }.entries) {
    testWidgets('master appends ${response.key} and can edit it', (
      tester,
    ) async {
      await mount(tester, response.value);
      await tester.enterText(field, 'Проверить насос.');
      await tapVoice(tester, 'Голосовое описание');
      await tapVoice(tester, 'Остановить и распознать');
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Проверить насос. Заменить подшипник.',
      );
      await tester.enterText(field, 'Проверить насос и заменить подшипник.');
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Проверить насос и заменить подшипник.',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('master empty HTTP 200 is localized and preserves manual input', (
    tester,
  ) async {
    await mount(tester, http.Response('', 200), language: 'kk');
    await tester.enterText(field, 'Сорғыны тексеру');
    await tapVoice(tester, 'Дауыспен сипаттау');
    await tapVoice(tester, 'Тоқтату және тану');
    expect(
      tester.widget<TextFormField>(field).controller!.text,
      'Сорғыны тексеру',
    );
    expect(
      find.textContaining('Сөйлеуді тану сервері бос жауап қайтарды'),
      findsOneWidget,
    );
    expect(find.text('Дауыспен сипаттау'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
