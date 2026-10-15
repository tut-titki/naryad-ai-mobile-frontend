import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/core/api/api_client.dart';
import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/features/orders/data/equipment_qr_api.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/orders/widgets/equipment_qr_button.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'helpers/backend_api_fixture.dart';
import 'package:mineral/features/auth/data/auth_session.dart'
    show AuthSession, AuthUser, MemoryTokenStorage;
import 'package:mineral/features/auth/widgets/auth_scope.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/orders/screens/orders_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';

Widget _masterApp({required Widget home}) {
  final session = AuthSession(storage: MemoryTokenStorage())
    ..user = AuthUser.fromJson({
      'id': 1,
      'fullName': 'Master',
      'role': 'MASTER',
    });
  addTearDown(session.dispose);
  return AuthScope(
    session: session,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

class _NoPhotos extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

void main() {
  testWidgets('master QR stays in app bar on overview and orders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = testApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(_masterApp(home: MasterShell(api: api)));
    await tester.pumpAndSettle();
    final qr = find.byKey(const ValueKey('scan-equipment-qr'));
    expect(qr, findsOneWidget);
    expect(
      find.ancestor(of: qr, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    expect(find.text('Создать наряд'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(qr, findsOneWidget);
    expect(
      find.ancestor(of: qr, matching: find.byType(AppBar)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: qr, matching: find.byType(OrdersScreen)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final role in ['MASTER', 'EXECUTOR', 'ADMIN', 'MANAGER', null]) {
    testWidgets('equipment QR is restricted to master: $role', (tester) async {
      var requests = 0;
      final api = testApi(
        handle: (request) async {
          requests++;
          return jsonResponse({'message': 'Unknown QR'}, status: 404);
        },
      );
      addTearDown(api.dispose);
      final session = AuthSession(storage: MemoryTokenStorage());
      if (role != null) {
        session.user = AuthUser.fromJson({
          'id': 1,
          'fullName': 'User',
          'role': role,
        });
      }
      addTearDown(session.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    EquipmentQrButton(api: api),
                    TextButton(
                      onPressed: () =>
                          showEquipmentQrSheet(context, api, 'missing'),
                      child: const Text('Direct entry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scan-equipment-qr')),
        role == 'MASTER' ? findsOneWidget : findsNothing,
      );
      if (role != 'MASTER') {
        await tester.tap(find.text('Direct entry'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(requests, 0);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'QR uses final path segment and never requests the scanned host',
    () async {
      expect(
        equipmentQrToken(
          'https://different.host/equipment/token-7/?print=1#qr',
        ),
        'token-7',
      );
      expect(equipmentQrToken('token-7'), 'token-7');
      expect(() => equipmentQrToken(''), throwsFormatException);
      for (final value in [
        'https://different.host/',
        'Любой текст из QR',
        '{"equipment":7}',
        'WIFI:T:WPA;S:Test;P:12345678;;',
        'mailto:person@example.com',
      ]) {
        expect(equipmentQrToken(value), value);
      }
      final client = ApiClient(
        baseUrl: 'https://backend.test',
        httpClient: MockClient((r) async {
          expect(r.url.host, 'backend.test');
          expect(r.url.path, '/api/equipment/qr/token-7');
          expect(r.headers['Authorization'], 'Bearer secret');
          return jsonResponse({
            'id': 7,
            'name': 'Pump',
            'area': {'id': 3, 'name': 'Area'},
          });
        }),
      );
      client.setAccessToken('secret');
      final result = await resolveEquipmentQr(
        client,
        'https://elsewhere/equipment/token-7',
      );
      expect(result.equipment.areaId, 3);
      expect(result.area.name, 'Area');
    },
  );

  test('unknown QR preserves 404 and PNG uses authentication', () async {
    final client = ApiClient(
      baseUrl: 'https://backend.test',
      httpClient: MockClient((r) async {
        expect(r.headers['Authorization'], 'Bearer secret');
        if (r.url.path.endsWith('qr.png')) {
          return http.Response.bytes([137, 80, 78, 71], 200);
        }
        return jsonResponse({'message': 'Unknown QR'}, status: 404);
      }),
    );
    client.setAccessToken('secret');
    await expectLater(
      resolveEquipmentQr(client, 'unknown'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
    );
    expect(await client.getBytes('/api/equipment/7/qr.png'), [137, 80, 78, 71]);
  });

  testWidgets(
    'sheet shows equipment and area, then opens a locked prefilled form',
    (tester) async {
      Map<String, dynamic>? sent;
      final storage = MemoryReferenceStorage();
      const ordinaryDraftKey = 'order-draft:https://backend.test:1';
      await storage.write(ordinaryDraftKey, [
        {'equipmentId': 99, 'description': 'Other repair'},
      ]);
      final api = testApi(
        handle: (r) async {
          if (r.url.path == '/api/references/executors') {
            return jsonResponse([executorJson()]);
          }
          if (r.url.path == '/api/recommendations/executors') {
            return jsonResponse([
              {
                'id': 7,
                'fullName': 'Test Executor',
                'score': 90,
                'employeeStatus': 'AVAILABLE',
              },
            ]);
          }
          if (r.url.path == '/api/work-orders' && r.method == 'POST') {
            sent = jsonDecode(r.body) as Map<String, dynamic>;
            return jsonResponse(orderJson(), status: 201);
          }
          if (r.url.path == '/api/equipment/qr/token-7') {
            return jsonResponse({
              'id': 7,
              'name': 'Scanned pump',
              'inventoryNumber': 'P-7',
              'area': {'id': 3, 'name': 'Scanned area'},
            });
          }
          // Deliberately absent from the reference catalog.
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        _masterApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showEquipmentQrSheet(
                  context,
                  api,
                  'https://other/equipment/token-7',
                  photoPicker: _NoPhotos(),
                  draftStorage: storage,
                ),
                child: const Text('Scan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      expect(find.text('Scanned pump'), findsOneWidget);
      expect(find.text('Участок: Scanned area'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('qr-create-order')));
      await tester.pumpAndSettle();
      final form = tester.widget<CreateOrderScreen>(
        find.byType(CreateOrderScreen),
      );
      expect(form.lockEquipment, isTrue);
      expect(form.initialEquipment!.id, 7);
      expect(find.text('Scanned pump'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('select-equipment')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('equipment-search')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('order-description')),
        'Repair scanned pump',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      final issue = find.byKey(const ValueKey('issue-order'));
      await tester.ensureVisible(issue);
      await tester.tap(issue);
      await tester.pumpAndSettle();
      expect(sent!['equipmentId'], 7);
      expect(sent!['areaId'], 3);
      expect(sent!['description'], 'Repair scanned pump');
      expect(
        (await storage.read(ordinaryDraftKey))!.first['description'],
        'Other repair',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unknown QR does not offer creation', (tester) async {
    final api = testApi(
      handle: (r) async => jsonResponse({'message': 'Unknown QR'}, status: 404),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      _masterApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showEquipmentQrSheet(context, api, 'missing'),
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Оборудование по этому QR не найдено'), findsOneWidget);
    expect(find.byKey(const ValueKey('qr-create-order')), findsNothing);
  });
}
