import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mineral/core/api/api_client.dart';
import 'package:mineral/core/api/backend_document.dart';
import 'package:mineral/core/services/photo_picker_service.dart';
import 'package:mineral/core/services/push_payload.dart';
import 'package:mineral/features/master/screens/dashboard_screen.dart';
import 'package:mineral/features/orders/data/work_orders_api.dart';
import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/features/orders/screens/equipment_history_screen.dart';
import 'package:mineral/features/orders/screens/order_detail_screen.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/orders/widgets/voice_description_button.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/shared/widgets/backend_section.dart';
import 'helpers/backend_api_fixture.dart';

class NoPhotos extends PhotoPickerService {
  @override
  Future<List<OrderPhoto>> takeRecoveredPhotos() async => [];
}

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);
void main() {
  Future<void> selectReference(
    WidgetTester tester,
    String key,
    String label,
  ) async {
    final field = find.byKey(ValueKey(key));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'master list applies scope filters and reset reloads the server',
    (tester) async {
      final queries = <Map<String, String>>[];
      final api = testApi(
        handle: (request) async {
          switch (request.url.path) {
            case '/api/references/areas':
              return jsonResponse([
                {'id': 1, 'name': 'Area A'},
              ]);
            case '/api/references/equipment':
              return jsonResponse([
                {'id': 2, 'name': 'Equipment A', 'areaId': 1},
              ]);
            case '/api/references/executors':
              return jsonResponse([executorJson()]);
            case '/api/references/brigades':
              return jsonResponse([
                {'id': 3, 'name': 'Brigade A', 'members': []},
              ]);
            case '/api/work-orders':
              queries.add(request.url.queryParameters);
              return jsonResponse([orderJson()]);
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: SingleChildScrollView(
              child: OrdersScreen(api: api, onOrder: (_) {}, onCreate: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Фильтры'));
      await tester.pumpAndSettle();
      await selectReference(tester, 'scope-areaId-null', 'Area A');
      await selectReference(tester, 'scope-equipmentId-null', 'Equipment A');
      await selectReference(tester, 'scope-executorId-null', 'Test Executor');
      await selectReference(tester, 'scope-brigadeId-null', 'Brigade A');
      await tester.ensureVisible(find.text('Применить'));
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      expect(queries.last, containsPair('areaId', '1'));
      expect(queries.last, containsPair('equipmentId', '2'));
      expect(queries.last, containsPair('assigneeId', '7'));
      expect(queries.last, containsPair('brigadeId', '3'));
      await tester.tap(find.byTooltip('Фильтры'));
      await tester.pumpAndSettle();
      final reset = find.text(
        AppLocalizations.of(
          tester.element(find.byType(OrdersScreen)),
        ).resetFilters,
      );
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Применить'));
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      for (final key in ['areaId', 'equipmentId', 'assigneeId', 'brigadeId']) {
        expect(queries.last.containsKey(key), false);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'rating uses server score, components and explanation in selected scope',
    (tester) async {
      Map<String, String>? query;
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/references/areas') {
            return jsonResponse([
              {'id': 1, 'name': 'Area A'},
            ]);
          }
          if (request.url.path == '/api/reports/ratings') {
            query = request.url.queryParameters;
            return jsonResponse([
              {
                'id': 7,
                'fullName': 'Rated Executor',
                'score': 79,
                'quality': 4.5,
                'closed': 12,
                'points': {
                  'quality': 40.5,
                  'onTime': 20,
                  'noReturns': 13.5,
                  'volume': 5,
                  'complexity': 1,
                  'rejects': -1,
                },
                'explanation': 'Server rating explanation',
                'formula': 'Server formula',
              },
            ]);
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: SingleChildScrollView(child: ReportsScreen(api: api)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Фильтры'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(ReportsScreen)),
          ).weekPeriod,
        ),
      );
      await tester.pumpAndSettle();
      await selectReference(tester, 'scope-areaId-null', 'Area A');
      final report = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(report);
      await tester.tap(report);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Рейтинг исполнителей').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Применить'));
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      expect(query, {'areaId': '1', 'period': 'week'});
      expect(find.text('Rated Executor'), findsNWidgets(2));
      expect(find.text('79/100'), findsOneWidget);
      expect(find.text('Качество'), findsOneWidget);
      expect(find.text('40.5'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
      expect(
        tester
            .widget<FractionallySizedBox>(
              find.byKey(const ValueKey('rating-bar-0')),
            )
            .widthFactor,
        .79,
      );
      await tester.ensureVisible(find.text('Rated Executor').last);
      await tester.tap(find.text('Rated Executor').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Server rating explanation'), findsOneWidget);
      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .toList();
      expect(bars.first.value, .79);
      expect(bars[1].value, .405);
      expect(find.text('Штраф за отказы: -1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'push suggestion reassigns only after the master confirms the executor',
    (tester) async {
      var posts = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/references/executors') {
            return jsonResponse([
              executorJson(),
              {...executorJson(), 'id': 8, 'fullName': 'Suggested Executor'},
            ]);
          }
          if (request.url.path == '/api/work-orders/773/reassign') {
            posts++;
            expect(jsonDecode(request.body), {'assigneeId': 8});
            return jsonResponse(orderJson());
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(OrderDetailScreen(api: api, orderId: 773, suggestedExecutorId: 8)),
      );
      await tester.pumpAndSettle();
      final button = find.text('Переназначить по предложению');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(posts, 0);
      expect(find.textContaining('Suggested Executor.'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppSheetContent),
          matching: find.text('Переназначить'),
        ),
      );
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'brigade assignment omits assignee and does not retry creation',
    () async {
      var calls = 0;
      final api = testApi(
        handle: (request) async {
          calls++;
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.url.path, '/api/work-orders');
          final body = jsonDecode(request.body) as Map;
          expect(body['brigadeId'], 3);
          expect(body.containsKey('assigneeId'), false);
          return jsonResponse({
            'error': 'Нет сотрудников на смене',
          }, status: 409);
        },
      );
      addTearDown(api.dispose);
      await expectLater(
        api.workOrders.createWorkOrder(
          CreateWorkOrderInput(
            type: WorkOrderType.planned,
            description: 'Ремонт насоса',
            areaId: 1,
            equipmentId: 2,
            brigadeId: 3,
            priority: WorkOrderPriority.normal,
            normativeId: 4,
          ),
          creationkey: 'brigade-create-test',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Нет сотрудников на смене',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test('list sends every documented master filter on every page', () async {
    final offsets = <String>[];
    final api = testApi(
      handle: (request) async {
        final query = request.url.queryParameters;
        expect(query, containsPair('areaId', '1'));
        expect(query, containsPair('equipmentId', '2'));
        expect(query, containsPair('assigneeId', '7'));
        expect(query, containsPair('brigadeId', '3'));
        expect(query, containsPair('status', 'ISSUED,QUEUED'));
        expect(query, containsPair('priority', 'EMERGENCY'));
        expect(query, containsPair('overdue', '1'));
        offsets.add(query['offset']!);
        return jsonResponse(
          query['offset'] == '0'
              ? List.generate(500, (i) => orderJson(id: i + 1))
              : [orderJson(id: 501)],
        );
      },
    );
    addTearDown(api.dispose);
    final orders = await api.workOrders.getAllWorkOrders(
      areaId: 1,
      equipmentId: 2,
      assigneeId: 7,
      brigadeId: 3,
      statuses: [WorkOrderStatus.issued, WorkOrderStatus.queued],
      priority: WorkOrderPriority.emergency,
      overdue: true,
    );
    expect(orders.length, 501);
    expect(offsets, ['0', '500']);
  });
  test('reports and PDF/XLSX exports send the same scope and period', () async {
    final scope = {
      'period': 'week',
      'from': '2026-10-01T00:00:00Z',
      'to': '2026-10-08T00:00:00Z',
      'areaId': 1,
      'equipmentId': 2,
      'executorId': 7,
      'brigadeId': 3,
    };
    final calls = <String>[];
    final api = testApi(
      handle: (request) async {
        calls.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer test-token');
        expect(request.url.queryParameters, containsPair('executorId', '7'));
        expect(
          request.url.queryParameters,
          containsPair('from', scope['from']),
        );
        expect(request.url.queryParameters, containsPair('brigadeId', '3'));
        if (request.url.path.contains('export.')) {
          expect(request.url.queryParameters['report'], 'materials');
          expect(request.url.queryParameters['groupBy'], 'equipment');
          return http.Response.bytes([1, 2, 3], 200);
        }
        return jsonResponse([]);
      },
    );
    addTearDown(api.dispose);
    await api.reports.getShift(filters: scope);
    await api.reports.getRatings(filters: scope);
    await api.reports.getBrigadeRatings(filters: scope);
    await api.reports.getDowntime(filters: scope);
    await api.reports.getMaterials(filters: {...scope, 'groupBy': 'equipment'});
    for (final pdf in [true, false]) {
      expect(
        await api.reports.export(
          pdf: pdf,
          report: 'materials',
          filters: {...scope, 'groupBy': 'equipment'},
        ),
        [1, 2, 3],
      );
    }
    expect(calls.length, 7);
  });
  test('comment is idempotent and parses COMMENT chronology', () async {
    final api = testApi(
      handle: (request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/work-orders/773/comment');
        expect(jsonDecode(request.body), {
          'comment': 'Ждём подшипник',
          'clientActionId': 'comment-unique-123',
        });
        return jsonResponse({
          'order': orderJson()
            ..['events'] = [
              {
                'id': 1,
                'action': 'COMMENT',
                'comment': 'Ждём подшипник',
                'createdAt': '2026-10-08T04:00:00Z',
              },
            ],
        }, status: 201);
      },
    );
    addTearDown(api.dispose);
    final order = await api.workOrders.addComment(
      773,
      comment: ' Ждём подшипник ',
      clientActionId: 'comment-unique-123',
    );
    expect(order.events.single.action, WorkOrderEventAction.comment);
  });
  test(
    'voice is a WAV multipart audio sent once with bearer authentication',
    () async {
      var calls = 0;
      final pcm = Uint8List.fromList([0, 0, 255, 127]);
      final audio = voiceWav(pcm);
      expect(ascii.decode(audio.sublist(0, 4)), 'RIFF');
      expect(
        ByteData.sublistView(audio).getUint32(40, Endian.little),
        pcm.length,
      );
      final api = testApi(
        handle: (request) async {
          calls++;
          expect(request.url.path, '/api/ai/transcribe');
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          final multipart = latin1.decode(request.bodyBytes);
          expect(multipart, contains('name="audio"'));
          expect(multipart, contains('description.wav'));
          expect(multipart, contains('RIFF'));
          expect(multipart, contains('audio/wav'));
          return calls == 1
              ? jsonResponse({'text': 'Течь сальника насоса'})
              : jsonResponse({'error': 'Речь не распознана'}, status: 422);
        },
      );
      addTearDown(api.dispose);
      expect(await transcribeVoice(api, audio), 'Течь сальника насоса');
      await expectLater(
        transcribeVoice(api, audio),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 422)),
      );
      expect(calls, 2);
    },
  );
  test('push suggestions are accepted only for NOT_ACCEPTED', () {
    expect(
      PushPayload({
        'type': 'NOT_ACCEPTED',
        'workOrderId': '773',
        'suggestedExecutorId': '7',
      }).suggestedExecutorId,
      7,
    );
    expect(
      PushPayload({
        'type': 'NEW_ORDER',
        'suggestedExecutorId': '7',
      }).suggestedExecutorId,
      isNull,
    );
    expect(
      PushPayload({
        'type': 'NOT_ACCEPTED',
        'suggestedExecutorId': '0',
      }).suggestedExecutorId,
      isNull,
    );
  });
  testWidgets('creation form submits a brigade with server-selected executor', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    final api = createFormApi(onCreate: (body) => sent = body);
    addTearDown(api.dispose);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CreateOrderScreen(
                    api: api,
                    draftStorage: MemoryReferenceStorage(),
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
    await tester.tap(find.byKey(const ValueKey('equipment-2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Ремонт насоса');
    await tester.ensureVisible(find.byKey(const ValueKey('order-advanced')));
    await tester.tap(find.byKey(const ValueKey('order-advanced')));
    await tester.pumpAndSettle();
    final mode = find
        .ancestor(
          of: find.text('Бригада'),
          matching: find.byType(SegmentedButton<bool>),
        )
        .first;
    await tester.ensureVisible(mode);
    await tester.tap(find.descendant(of: mode, matching: find.text('Бригада')));
    await tester.pumpAndSettle();
    final brigade = find.byKey(const ValueKey('brigade-null'));
    await tester.ensureVisible(brigade);
    await tester.tap(brigade);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brigade A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выдать наряд'));
    await tester.pumpAndSettle();
    expect(sent!['brigadeId'], 1);
    expect(sent!.containsKey('assigneeId'), false);
    expect(tester.takeException(), isNull);
  });
  testWidgets('equipment search selects its area and issues an order quickly', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    final api = testApi(
      handle: (request) async {
        switch (request.url.path) {
          case '/api/references/areas':
            return jsonResponse([
              {'id': 1, 'name': 'Area A'},
              {'id': 2, 'name': 'Area B'},
            ]);
          case '/api/references/equipment':
            final area = request.url.queryParameters['areaId'];
            return jsonResponse(
              area == '2'
                  ? [
                      {'id': 4, 'name': 'Pump A', 'areaId': 2},
                      {'id': 5, 'name': 'Pump B', 'areaId': 2},
                    ]
                  : [
                      {'id': 2, 'name': 'Conveyor A', 'areaId': 1},
                      {'id': 3, 'name': 'Conveyor B', 'areaId': 1},
                      if (area == null) ...[
                        {'id': 4, 'name': 'Pump A', 'areaId': 2},
                        {'id': 5, 'name': 'Pump B', 'areaId': 2},
                      ],
                    ],
            );
          case '/api/references/executors':
            return jsonResponse([
              executorJson(),
              {...executorJson(), 'id': 8, 'fullName': 'Second Executor'},
            ]);
          case '/api/references/normatives':
            return jsonResponse([
              {'id': 3, 'name': 'Normative', 'hours': '2'},
            ]);
          case '/api/recommendations/executors':
            return jsonResponse([
              {
                'id': 7,
                'fullName': 'Test Executor',
                'employeeStatus': 'AVAILABLE',
                'queue': 0,
                'score': 80,
              },
            ]);
          case '/api/work-orders':
            if (request.method == 'POST') {
              sent = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
              return jsonResponse(orderJson());
            }
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CreateOrderScreen(
                    api: api,
                    draftStorage: MemoryReferenceStorage(),
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

    var taps = 0;
    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      taps++;
      await tester.pumpAndSettle();
    }

    await tap(find.text('Open'));
    await tester.enterText(
      find.byKey(const ValueKey('equipment-search')),
      'Pump B',
    );
    await tester.pumpAndSettle();
    await tap(find.byKey(const ValueKey('equipment-5')));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('order-description')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.enterText(
      find.byKey(const ValueKey('order-description')),
      'Проверить насос',
    );
    await tester.pumpAndSettle();
    await tap(find.text('Выдать наряд'));

    expect(taps, 3);
    expect(sent, isNotNull);
    expect(sent!['areaId'], 2);
    expect(sent!['equipmentId'], 5);
    expect(sent!['assigneeId'], 7);
    expect(sent!['type'], 'PLANNED');
    expect(sent!['priority'], 'NORMAL');
    expect(tester.takeException(), isNull);

    sent = null;
    await tap(find.text('Open'));
    await tap(find.byKey(const ValueKey('equipment-2')));
    await tester.enterText(
      find.byKey(const ValueKey('order-description')),
      'Проверить назначение',
    );
    await tester.pumpAndSettle();
    await tap(find.byKey(const ValueKey('select-executor')));
    await tester.enterText(find.byType(TextField).last, 'Second Executor');
    await tester.pumpAndSettle();
    await tap(find.widgetWithText(ListTile, 'Second Executor').last);
    await tap(find.text('Выдать наряд'));
    expect(sent!['assigneeId'], 8);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'master sees completion, timing, downtime and explicit review warning',
    (tester) async {
      final api = testApi(
        handle: (request) async => request.url.path == '/api/work-orders/773'
            ? jsonResponse(
                orderJson(status: 'AI_REVIEW')
                  ..['completionText'] = 'Подшипник заменён'
                  ..['actualDowntimeMinutes'] = 45
                  ..['timing'] = {
                    'normativeHours': '2',
                    'actualHours': '2.4',
                    'vsNormativePercent': 120,
                    'deadlineMet': false,
                    'overdueMinutes': 35,
                  }
                  ..['aiAssessment'] = {
                    'verdict': 'REWORK_REQUIRED',
                    'needsMasterReview': true,
                    'photoComment': 'Проверьте фото',
                    'rawResponse': 'PRIVATE MODEL RESPONSE',
                  },
              )
            : null,
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(host(OrderDetailScreen(api: api, orderId: 773)));
      await tester.pumpAndSettle();
      expect(find.text('Нужна проверка мастером'), findsOneWidget);
      expect(find.text('Подшипник заменён'), findsOneWidget);
      expect(find.text('45 мин'), findsOneWidget);
      expect(find.text('120.0%'), findsOneWidget);
      expect(find.text('2.4 ч'), findsOneWidget);
      expect(find.text('PRIVATE MODEL RESPONSE'), findsNothing);
      expect(find.text('Принять и закрыть'), findsOneWidget);
      expect(find.text('На доработку'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('equipment history handles documented null response', (
    tester,
  ) async {
    final api = testApi(
      handle: (request) async => request.url.path == '/api/equipment/2/history'
          ? jsonResponse(null)
          : null,
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      host(EquipmentHistoryScreen(api: api, equipmentId: 2)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Оборудование не найдено'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('rawResponse is omitted even in generic nested reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          body: BackendDocumentView(
            document: BackendDocument.fromJson({
              'rawResponse': 'PRIVATE',
              'aiAssessment': {
                'rawResponse': 'NESTED PRIVATE',
                'explanation': 'Пояснение мастеру',
              },
            }),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('PRIVATE'), findsNothing);
    expect(find.textContaining('Пояснение мастеру'), findsOneWidget);
  });
  testWidgets(
    'board counters are authoritative and refresh at most once a second',
    (tester) async {
      var calls = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path != '/api/work-orders/board') return null;
          calls++;
          return jsonResponse(
            boardJson()
              ..['counters'] = {
                'issued': 14,
                'completed': 9,
                'overdue': 2,
                'equipmentInDowntime': 1,
              },
          );
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: SingleChildScrollView(
              child: DashboardScreen(api: api, onOrder: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('14'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(calls, 1);
      for (var i = 0; i < 5; i++) {
        api.realtime.invalidate();
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, 1);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
