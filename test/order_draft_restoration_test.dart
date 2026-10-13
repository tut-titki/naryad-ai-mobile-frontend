import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:mineral/shared/models/models.dart';
import 'helpers/backend_api_fixture.dart';

class NoPhotos extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

void main() {
  for (final scenario in [
    'normative error',
    'new executor',
    'close after selection',
    'normative removed',
  ]) {
    testWidgets('draft survives $scenario during equipment restoration', (
      tester,
    ) async {
      const key = 'order-draft:https://backend.test:test';
      final storage = MemoryReferenceStorage();
      await storage.write(key, [
        {
          'equipmentId': 1,
          'executorId': 8,
          'normativeId': 3,
          'faultCodeId': 4,
          'manualExecutor': true,
          'manualWork': true,
          'description': '',
          'photos': <Object>[],
        },
      ]);
      final response = Completer<http.Response>();
      var started = false;
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
                {...executorJson(), 'id': 8, 'fullName': 'Saved executor'},
              ]);
            case '/api/references/fault-codes':
              return jsonResponse([
                {'id': 4, 'code': 'M-02', 'name': 'Bearing'},
              ]);
            case '/api/references/normatives':
              started = true;
              return response.future;
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
            photoPicker: NoPhotos(),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(started, isTrue);
      if (scenario == 'new executor' || scenario == 'close after selection') {
        final picker = find.byKey(const ValueKey('select-executor'));
        await tester.ensureVisible(picker);
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test Executor'));
        await tester.pumpAndSettle();
      }
      if (scenario == 'close after selection') {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      response.complete(
        scenario == 'normative error'
            ? jsonResponse({'error': 'Unavailable'}, status: 503)
            : scenario == 'normative removed'
            ? jsonResponse([])
            : jsonResponse([
                {'id': 3, 'name': 'Repair', 'hours': '2.5'},
              ]),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      final actual = (await storage.read(key))!.single;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      if (scenario == 'normative error') {
        expect(
          actual['normativeId'],
          3,
          reason: 'A request error must not delete the saved normative',
        );
        expect(actual['faultCodeId'], 4);
        expect(actual['executorId'], 8);
      } else if (scenario == 'normative removed') {
        expect(
          actual['normativeId'],
          isNull,
          reason: 'A successful load must invalidate a removed normative',
        );
      } else {
        expect(
          actual['executorId'],
          7,
          reason: 'Restoration must not overwrite the new manual selection',
        );
      }
      expect(actual['manualWork'], isTrue);
      expect(actual['manualExecutor'], isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
