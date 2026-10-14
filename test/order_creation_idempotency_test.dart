import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'helpers/backend_api_fixture.dart';
import 'order_draft_restoration_test.dart' show NoPhotos;

class _FailingStorage extends MemoryReferenceStorage {
  bool failWrites = false;

  @override
  Future<void> write(String key, List<Map<String, dynamic>> items) async {
    if (failWrites) throw StateError('Disk unavailable');
    await super.write(key, items);
  }
}

void main() {
  for (final scenario in ['retry', 'reopen', 'write failure']) {
    testWidgets('creation preserves request and key: $scenario', (
      tester,
    ) async {
      const key = 'order-draft:https://backend.test:test';
      final storage = _FailingStorage();
      await storage.write(key, [
        {
          'equipmentId': 2,
          'description': 'Original repair',
          'executorId': 7,
          'manualExecutor': true,
          'photos': [
            {
              'name': 'before.jpg',
              'bytes': base64Encode([1, 2, 3]),
            },
          ],
        },
      ]);
      final bodies = <String>[];
      final keys = <String?>[];
      var uploads = 0;
      final api = testApi(
        handle: (request) async {
          switch (request.url.path) {
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
            case '/api/uploads':
              uploads++;
              return jsonResponse({'url': '/uploads/photo-$uploads.jpg'});
            case '/api/work-orders':
              if (request.method != 'POST') return null;
              final saved = (await storage.read(key))!.single;
              expect(saved['creationKey'], request.headers['Idempotency-Key']);
              expect(saved['creationPayload'], jsonDecode(request.body));
              bodies.add(request.body);
              keys.add(request.headers['Idempotency-Key']);
              if (bodies.length == 1) {
                throw http.ClientException('Response lost after server commit');
              }
              return jsonResponse(orderJson(), status: 201);
          }
          return null;
        },
      );
      addTearDown(api.dispose);

      Future<void> open() async {
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
      }

      await open();
      expect(
        find.byKey(const ValueKey('saved-order-retry-notice')),
        findsNothing,
      );
      storage.failWrites = scenario == 'write failure';
      await tester.tap(find.byKey(const ValueKey('issue-order')));
      await tester.pumpAndSettle();
      if (scenario == 'write failure') {
        expect(bodies, isEmpty, reason: 'POST must wait for durable storage');
        storage.failWrites = false;
      } else {
        expect(bodies, hasLength(1));
        expect(keys.single, isNotEmpty);
        expect(
          find.byKey(const ValueKey('saved-order-retry-notice')),
          findsOneWidget,
        );
        if (scenario == 'reopen') {
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          await open();
          expect(
            find.byKey(const ValueKey('saved-order-retry-notice')),
            findsOneWidget,
          );
        }
        // Current form validation must not block replay of the saved request.
        await tester.enterText(
          find.byKey(const ValueKey('order-description')),
          '',
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.tap(find.byKey(const ValueKey('issue-order')));
        await tester.pumpAndSettle();
        expect(bodies, hasLength(2));
        expect(bodies[1], bodies[0]);
        expect(keys[1], keys[0]);
        expect(uploads, 1, reason: 'Replay must reuse uploaded photo URLs');
        expect(await storage.read(key), isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
