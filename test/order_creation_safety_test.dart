import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mineral/features/orders/screens/order_detail_screen.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/models/models.dart';
import 'helpers/backend_api_fixture.dart';
import 'order_draft_restoration_test.dart' show NoPhotos;

class ReadFailsOnce extends MemoryReferenceStorage {
  var fail = true;
  @override
  Future<List<Map<String, dynamic>>?> read(String key) async {
    if (fail) {
      fail = false;
      throw StateError('Temporary storage error');
    }
    return super.read(key);
  }
}

class _DiscardWriteFails extends MemoryReferenceStorage {
  bool rejectWrites = false;
  @override
  Future<void> write(String key, List<Map<String, dynamic>> items) async {
    if (rejectWrites) throw StateError('Storage unavailable');
    await super.write(key, items);
  }
}

class _DelayedPhotos extends NoPhotos {
  final result = Completer<List<OrderPhoto>>();
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() => result.future;
}

void main() {
  testWidgets('discard ignores photos recovered after the reset', (
    tester,
  ) async {
    const key = 'order-draft:https://backend.test:test';
    final storage = MemoryReferenceStorage();
    await storage.write(key, [
      {'description': 123},
    ]);
    final picker = _DelayedPhotos();
    final api = createFormApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CreateOrderScreen(
          api: api,
          draftStorage: storage,
          photoPicker: picker,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discard-order-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-discard-order-draft')));
    await tester.pumpAndSettle();
    picker.result.complete([
      OrderPhoto(name: 'old.jpg', bytes: Uint8List.fromList([1, 2, 3])),
    ]);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect((await storage.read(key))!.single['photos'], isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ru', 'kk']) {
    for (final scenario in ['cancel', 'confirm', 'write fails']) {
      testWidgets('discard corrupt draft: $scenario in $language', (
        tester,
      ) async {
        final storage = _DiscardWriteFails();
        const key = 'order-draft:https://backend.test:test';
        final original = <String, dynamic>{
          'equipmentId': 2,
          'description': 'Old issue',
          'comment': 'Old comment',
          'executorId': 7,
          'manualExecutor': true,
          'manualWork': true,
          'normativeId': 3,
          'faultCodeId': 4,
          'priority': 'HIGH',
          'customDeadline': true,
          'deadline': DateTime.now()
              .subtract(const Duration(days: 7))
              .toIso8601String(),
          'deadlineHours': 8,
          'photos': [
            {'name': 'broken.jpg', 'bytes': '!'},
          ],
        };
        await storage.write(key, [original]);
        Map<String, dynamic>? created;
        final api = createFormApi(onCreate: (body) => created = body);
        addTearDown(api.dispose);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CreateOrderScreen(
                        api: api,
                        draftStorage: storage,
                        photoPicker: NoPhotos(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final s = AppLocalizations.of(
          tester.element(find.byType(CreateOrderScreen)),
        );
        expect(find.text(s.draftLoadFailed), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('discard-order-draft')));
        await tester.pumpAndSettle();
        expect(find.text(s.discardOrderDraftMessage), findsOneWidget);
        storage.rejectWrites = scenario == 'write fails';
        await tester.tap(
          scenario == 'cancel'
              ? find.text(s.cancel)
              : find.byKey(const ValueKey('confirm-discard-order-draft')),
        );
        await tester.pumpAndSettle();
        if (scenario == 'confirm') {
          expect(find.text(s.draftLoadFailed), findsNothing);
          expect(
            tester
                .widget<TextFormField>(
                  find.byKey(const ValueKey('order-description')),
                )
                .controller!
                .text,
            isEmpty,
          );
          await tester.tap(find.byKey(const ValueKey('equipment-2')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('order-description')),
            'New repair',
          );
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<FilledButton>(find.byKey(const ValueKey('issue-order')))
                .onPressed,
            isNotNull,
          );
          await tester.tap(find.byKey(const ValueKey('issue-order')));
          await tester.pumpAndSettle();
          expect(created!['description'], 'New repair');
          expect(created!['priority'], 'NORMAL');
          expect(created!['comment'], isNull);
          expect(created!['normativeId'], isNull);
          expect(created!['faultCodeId'], isNull);
          expect(created!['beforePhotoUrls'], isNull);
          expect(
            DateTime.parse(
              created!['deadline'] as String,
            ).isAfter(DateTime.now()),
            isTrue,
          );
          expect(await storage.read(key), isEmpty);
        } else {
          await tester.pump(const Duration(seconds: 1));
          expect((await storage.read(key))!.single, original);
          expect(find.text(s.draftLoadFailed), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(find.byKey(const ValueKey('issue-order')))
                .onPressed,
            isNull,
          );
          if (scenario == 'write fails') {
            expect(find.text(s.orderDraftDiscardFailed), findsOneWidget);
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('draft read failure preserves data and allows restoration retry', (
    tester,
  ) async {
    final storage = ReadFailsOnce();
    const key = 'order-draft:https://backend.test:test';
    await storage.write(key, [
      {'description': 'Saved report', 'photos': <Object>[]},
    ]);
    final api = testApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CreateOrderScreen(
          api: api,
          draftStorage: storage,
          photoPicker: NoPhotos(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    final stored = (await storage.read(key))!.single;
    expect(stored['description'], 'Saved report');
    expect(
      find.text(
        'Не удалось восстановить черновик. Повторите попытку — сохранённые данные не изменены.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('issue-order')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('order-description')),
          )
          .controller!
          .text,
      'Saved report',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(stored['description'], 'Saved report');
    expect(tester.takeException(), isNull);
  });
  testWidgets('corrupt draft is preserved when leaving the error screen', (
    tester,
  ) async {
    final storage = MemoryReferenceStorage();
    const key = 'order-draft:https://backend.test:test';
    final original = <String, dynamic>{
      'description': 123,
      'photos': <Object>[],
    };
    await storage.write(key, [original]);
    final api = testApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CreateOrderScreen(
          api: api,
          draftStorage: storage,
          photoPicker: NoPhotos(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect((await storage.read(key))!.single, original);
    expect(tester.takeException(), isNull);
  });
  for (final days in [-7, 900]) {
    testWidgets('editing a deadline outside calendar bounds: $days days', (
      tester,
    ) async {
      final api = testApi(
        handle: (r) async {
          if (r.url.path == '/api/work-orders/773') {
            return jsonResponse({
              ...orderJson(),
              'deadline': DateTime.now()
                  .add(Duration(days: days))
                  .toUtc()
                  .toIso8601String(),
            });
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(home: OrderDetailScreen(api: api, orderId: 773)),
      );
      await tester.pumpAndSettle();
      final edit = find.text('Изменить');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithIcon(OutlinedButton, Icons.event_outlined),
      );
      await tester.pump();
      final failure = tester.takeException();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(failure, isNull);
    });
  }

  for (final scenario in [
    'back during send',
    'forced removal',
    'request error',
  ]) {
    testWidgets('creation handles $scenario without losing its draft outcome', (
      tester,
    ) async {
      final storage = MemoryReferenceStorage();
      const key = 'order-draft:https://backend.test:test';
      await storage.write(key, [
        {
          'equipmentId': 2,
          'description': 'Repair pump',
          'executorId': 7,
          'manualExecutor': true,
          'photos': <Object>[],
        },
      ]);
      final reply = Completer<http.Response>();
      var posted = false;
      final api = testApi(
        handle: (r) async {
          switch (r.url.path) {
            case '/api/references/areas':
              return jsonResponse([
                {'id': 1, 'name': 'Area'},
              ]);
            case '/api/references/equipment':
              return jsonResponse([
                {'id': 2, 'name': 'Pump', 'areaId': 1},
              ]);
            case '/api/references/executors':
              return jsonResponse([executorJson()]);
            case '/api/recommendations/executors':
              return jsonResponse([
                {
                  'id': 7,
                  'fullName': 'Test Executor',
                  'score': 90,
                  'employeeStatus': 'AVAILABLE',
                },
              ]);
            case '/api/recommendations/work':
              return jsonResponse({});
            case '/api/work-orders':
              if (r.method == 'POST') {
                posted = true;
                return reply.future;
              }
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateOrderScreen(
                      api: api,
                      draftStorage: storage,
                      photoPicker: NoPhotos(),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('issue-order')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(posted, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CreateOrderScreen), findsOneWidget);
      if (scenario == 'forced removal') {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
      reply.complete(
        scenario == 'request error'
            ? jsonResponse({'error': 'Unavailable'}, status: 503)
            : jsonResponse(orderJson(), status: 201),
      );
      await tester.pumpAndSettle();
      if (scenario == 'request error') {
        expect(find.byType(CreateOrderScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }
      expect(find.byType(CreateOrderScreen), findsNothing);
      final saved = await storage.read(key);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      if (scenario == 'request error') {
        expect(saved!.single['description'], 'Repair pump');
      } else {
        expect(
          saved,
          isEmpty,
          reason:
              'The server accepted creation; this draft must not be offered for a second submission',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
