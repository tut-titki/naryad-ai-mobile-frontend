import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:record/record.dart';

import 'helpers/backend_api_fixture.dart';
import 'helpers/recording_fixture.dart';

class _NoPhotos extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

void main() {
  testWidgets('voice issuance takes five taps', (tester) async {
    final original = RecordPlatform.instance;
    final recorder = TestRecorderPlatform();
    RecordPlatform.instance = recorder;
    addTearDown(() async {
      RecordPlatform.instance = original;
      await recorder.states.close();
    });
    Map<String, dynamic>? sent;
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
          case '/api/ai/transcribe':
            return jsonResponse({'text': 'Repair pump'});
          case '/api/work-orders':
            sent = jsonDecode(r.body) as Map<String, dynamic>;
            return jsonResponse(orderJson(), status: 201);
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateOrderScreen(api: api, photoPicker: _NoPhotos()),
                ),
              ),
              child: const Text('Create'),
            ),
          ),
        ),
      ),
    );
    var taps = 0;
    Future<void> tap(Finder f, {bool voice = false}) async {
      await tester.ensureVisible(f);
      if (voice) {
        await tester.runAsync(() async {
          await tester.tap(f);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
      } else {
        await tester.tap(f);
      }
      taps++;
      await tester.pumpAndSettle();
    }

    await tap(find.text('Create'));
    await tap(find.byKey(const ValueKey('equipment-2')));
    await tap(find.text('Голосовое описание'), voice: true);
    await tap(find.text('Остановить и распознать'), voice: true);
    await tap(find.byKey(const ValueKey('issue-order')));
    expect(taps, 5);
    expect(sent!['description'], 'Repair pump');
    expect(sent!['assigneeId'], 7);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  for (final failAi in [false, true]) {
    testWidgets('three taps issue an order; AI failure=$failAi', (
      tester,
    ) async {
      Map<String, dynamic>? sent;
      final full = Completer<void>();
      final calls = <bool>[];
      final api = testApi(
        handle: (r) async {
          switch (r.url.path) {
            case '/api/references/equipment':
              return jsonResponse([
                {'id': 2, 'name': 'Pump', 'areaId': 1},
              ]);
            case '/api/references/areas':
              return jsonResponse([
                {'id': 1, 'name': 'Area'},
              ]);
            case '/api/references/executors':
              return jsonResponse([executorJson()]);
            case '/api/references/normatives':
              return jsonResponse([
                {'id': 3, 'name': 'Repair', 'hours': '2.5'},
              ]);
            case '/api/recommendations/executors':
              return jsonResponse([
                {
                  'id': 7,
                  'fullName': 'Test Executor',
                  'employeeStatus': 'AVAILABLE',
                  'statusText': 'свободен',
                  'score': 90,
                },
              ]);
            case '/api/recommendations/work':
              final body = jsonDecode(r.body) as Map;
              calls.add(body['fast'] == true);
              if (body['fast'] != true) {
                await full.future;
              }
              if (failAi) {
                return jsonResponse({'error': 'Unavailable'}, status: 502);
              }
              return jsonResponse({
                'faultCodeId': 4,
                'normativeId': 3,
                'faultCode': {'id': 4, 'code': 'M-02', 'name': 'Bearing'},
                'normative': {'id': 3, 'name': 'Repair', 'hours': '2.5'},
              });
            case '/api/work-orders':
              sent = jsonDecode(r.body) as Map<String, dynamic>;
              return jsonResponse(orderJson(), status: 201);
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateOrderScreen(api: api, photoPicker: _NoPhotos()),
                  ),
                ),
                child: const Text('Create'),
              ),
            ),
          ),
        ),
      );
      var taps = 0;
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
        taps++;
        await tester.pumpAndSettle();
      }

      await tap(find.text('Create'));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('issue-order')))
            .onPressed,
        isNull,
      );
      await tap(find.byKey(const ValueKey('equipment-2')));
      final description = find.byKey(const ValueKey('order-description'));
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: description,
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(description, 'Replace bearing');
      await tester.pump(const Duration(milliseconds: 799));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(calls, containsAll([true, false]));
      await tap(find.byKey(const ValueKey('issue-order')));
      expect(taps, 3);
      expect(sent!['equipmentId'], 2);
      expect(sent!['areaId'], 1);
      expect(sent!['assigneeId'], 7);
      expect(sent!['priority'], 'NORMAL');
      expect(sent!['type'], 'PLANNED');
      if (failAi) {
        expect(sent!['deadline'], isNotNull);
        expect(sent!.containsKey('normativeId'), isFalse);
      } else {
        expect(sent!['normativeId'], 3);
        expect(sent!['faultCodeId'], 4);
        expect(sent!.containsKey('deadline'), isFalse);
      }
      full.complete();
      await tester.pumpAndSettle();
      expect(find.text('Create'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'manual executor survives full AI response and draft is restored',
    (tester) async {
      final storage = MemoryReferenceStorage();
      final full = Completer<void>();
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
              return jsonResponse([
                executorJson(),
                {...executorJson(), 'id': 8, 'fullName': 'Second'},
              ]);
            case '/api/recommendations/executors':
              return jsonResponse([
                for (final id in [7, 8])
                  {
                    'id': id,
                    'fullName': id == 7 ? 'Test Executor' : 'Second',
                    'score': 90,
                    'employeeStatus': 'AVAILABLE',
                  },
              ]);
            case '/api/recommendations/work':
              if (!(jsonDecode(r.body) as Map).containsKey('fast')) {
                await full.future;
              }
              return jsonResponse({});
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      Future<void> mount() async {
        await tester.pumpWidget(
          MaterialApp(
            home: CreateOrderScreen(
              api: api,
              photoPicker: _NoPhotos(),
              draftStorage: storage,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount();
      await tester.tap(find.byKey(const ValueKey('equipment-2')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('order-description')),
        'Repair pump',
      );
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('executor-8')));
      await tester.tap(find.byKey(const ValueKey('executor-8')));
      await tester.pumpAndSettle();
      full.complete();
      await tester.pumpAndSettle();
      Icon selectedIcon() => tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey('executor-8')),
          matching: find.byIcon(Icons.check_circle),
        ),
      );
      expect(selectedIcon().icon, Icons.check_circle);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('order-description')),
            )
            .controller!
            .text,
        'Repair pump',
      );
      expect(selectedIcon().icon, Icons.check_circle);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final closeDuringLoad in [false, true]) {
    testWidgets(
      'manual draft survives slow equipment restore; close=$closeDuringLoad',
      (tester) async {
        final storage = MemoryReferenceStorage();
        const draftKey = 'order-draft:https://backend.test:test';
        final saved = <String, dynamic>{
          'equipmentId': 1,
          'executorId': 8,
          'normativeId': 3,
          'faultCodeId': 4,
          'manualExecutor': true,
          'manualWork': true,
          'description': '',
          'photos': <Object>[],
        };
        await storage.write(draftKey, [saved]);
        Future<void> expectSavedFields() async {
          final actual = (await storage.read(draftKey))!.single;
          for (final field in saved.keys) {
            expect(actual[field], saved[field], reason: field);
          }
        }

        final normatives = Completer<http.Response>();
        var loadingStarted = false;
        final api = testApi(
          handle: (request) async {
            switch (request.url.path) {
              case '/api/references/areas':
                return jsonResponse([
                  {'id': 1, 'name': 'Area'},
                ]);
              case '/api/references/equipment':
                return jsonResponse([
                  {'id': 1, 'name': 'Pump', 'areaId': 1},
                ]);
              case '/api/references/executors':
                return jsonResponse([
                  executorJson(),
                  {...executorJson(), 'id': 8, 'fullName': 'Manual executor'},
                ]);
              case '/api/references/fault-codes':
                return jsonResponse([
                  {'id': 4, 'code': 'M-02', 'name': 'Bearing'},
                ]);
              case '/api/references/normatives':
                loadingStarted = true;
                return normatives.future;
              case '/api/recommendations/executors':
                return jsonResponse([
                  {
                    'id': 7,
                    'fullName': 'Test Executor',
                    'score': 90,
                    'employeeStatus': 'AVAILABLE',
                  },
                ]);
            }
            return null;
          },
        );
        addTearDown(api.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: CreateOrderScreen(
              api: api,
              draftStorage: storage,
              photoPicker: _NoPhotos(),
            ),
          ),
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(loadingStarted, isTrue);
        await tester.pump(const Duration(seconds: 1));
        await expectSavedFields();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        await expectSavedFields();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        if (closeDuringLoad) {
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          await expectSavedFields();
        }
        normatives.complete(
          jsonResponse([
            {'id': 3, 'name': 'Repair', 'hours': '2.5'},
          ]),
        );
        await tester.pumpAndSettle();
        if (!closeDuringLoad) {
          await tester.pump(const Duration(seconds: 1));
          final restored = (await storage.read(draftKey))!.single;
          for (final field in [
            'executorId',
            'normativeId',
            'faultCodeId',
            'manualWork',
            'manualExecutor',
          ]) {
            expect(restored[field], saved[field], reason: field);
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('late draft equipment response keeps the newer selection', (
    tester,
  ) async {
    final storage = MemoryReferenceStorage();
    await storage.write('order-draft:https://backend.test:test', [
      {
        'equipmentId': 1,
        'executorId': 8,
        'manualExecutor': true,
        'description': '',
        'photos': <Object>[],
      },
    ]);
    final oldNormatives = Completer<http.Response>();
    final api = testApi(
      handle: (request) async {
        switch (request.url.path) {
          case '/api/references/areas':
            return jsonResponse([
              {'id': 1, 'name': 'Area'},
            ]);
          case '/api/references/equipment':
            return jsonResponse([
              {'id': 1, 'name': 'Old', 'areaId': 1},
              {'id': 2, 'name': 'New', 'areaId': 1},
            ]);
          case '/api/references/executors':
            return jsonResponse([
              executorJson(),
              {...executorJson(), 'id': 8, 'fullName': 'Old executor'},
            ]);
          case '/api/references/normatives':
            if (request.url.queryParameters['equipmentId'] == '1') {
              return oldNormatives.future;
            }
            return jsonResponse([]);
          case '/api/recommendations/executors':
            final equipmentId = int.parse(
              request.url.queryParameters['equipmentId']!,
            );
            final id = equipmentId == 1 ? 8 : 7;
            return jsonResponse([
              {
                'id': id,
                'fullName': id == 8 ? 'Old executor' : 'Test Executor',
                'score': 90,
                'employeeStatus': 'AVAILABLE',
              },
            ]);
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: CreateOrderScreen(
          api: api,
          draftStorage: storage,
          photoPicker: _NoPhotos(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('select-equipment')));
    await tester.tap(find.byKey(const ValueKey('select-equipment')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(
      (await storage.read(
        'order-draft:https://backend.test:test',
      ))!.single['equipmentId'],
      2,
    );
    oldNormatives.complete(jsonResponse([]));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('executor-7')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
