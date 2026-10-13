import 'package:mineral/features/executor/models/executor_rating_period.dart';
import 'package:mineral/features/executor/models/executor_order_queue.dart';
import 'dart:async';
import 'package:mineral/features/executor/screens/executor_profile_screen.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:mineral/features/executor/data/pending_action_storage_io.dart';
import 'package:mineral/features/executor/models/pending_action.dart';
import 'package:mineral/features/executor/data/pending_action_storage.dart';
import 'package:mineral/core/services/photo_upload_rules.dart';
import 'package:mineral/features/executor/screens/executor_order_screen.dart';
import 'package:mineral/features/executor/screens/executor_order_loader.dart';
import 'package:mineral/features/executor/models/executor_order_actions.dart';
import 'package:flutter/material.dart';
import 'package:mineral/features/executor/screens/executor_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/executor/data/api_executor_repository.dart';
import 'package:mineral/features/executor/data/executor_api.dart';
import 'package:mineral/features/executor/data/executor_repository.dart';
import 'package:mineral/features/executor/data/execution_draft_storage_io.dart';
import 'package:mineral/shared/models/models.dart';

const user = {
  'id': 5,
  'fullName': 'Worker',
  'role': 'EXECUTOR',
  'language': 'ru',
};
Map<String, dynamic> order(int id, String status, {bool full = false}) => {
  'id': id,
  'number': 'H-00$id',
  'description': 'Repair',
  'status': status,
  'priority': 'EMERGENCY',
  'type': 'PLANNED',
  'assigneeId': 5,
  'deadline': '2026-10-07T10:00:00Z',
  'createdAt': '2026-10-06T09:00:00Z',
  'updatedAt': '2026-10-06T10:00:00Z',
  'comment': null,
  'area': {'name': 'Area'},
  'equipment': {'name': 'Pump'},
  if (full) ...{
    'completionText': 'Completed',
    'faultCode': {'id': 11, 'code': 'P-12', 'name': 'Seal'},
    'normative': {'hours': '1.5'},
    'materialUsages': [
      {
        'materialId': 23,
        'quantity': '1.5',
        'material': {'name': 'Seal', 'unit': 'pcs'},
      },
    ],
    'photos': [],
    'events': [
      {
        'action': 'START',
        'toStatus': 'IN_PROGRESS',
        'createdAt': '2026-10-06T09:00:00Z',
        'actor': {'fullName': 'Worker'},
        'comment': null,
      },
      {
        'action': 'PAUSE',
        'toStatus': 'PAUSED',
        'createdAt': '2026-10-06T09:20:00Z',
        'actor': {'fullName': 'Worker'},
        'comment': 'Break',
      },
      {
        'action': 'RESUME',
        'toStatus': 'IN_PROGRESS',
        'createdAt': '2026-10-06T09:40:00Z',
        'actor': {'fullName': 'Worker'},
        'comment': null,
      },
    ],
  },
};
http.Response json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  late Directory directory;
  late AuthSession session;
  late ApiExecutorRepository repository;
  late FileExecutionDraftStorage drafts;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) handler;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('executor_api_test');
    drafts = FileExecutionDraftStorage(directory: () async => directory);
    requests = [];
    handler = (request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/me')) return json(user);
      if (path.endsWith('/fault-codes')) {
        return json([
          {'id': 11, 'code': 'P-12', 'name': 'Seal'},
        ]);
      }
      if (path.endsWith('/materials')) {
        return json([
          {'id': 23, 'name': 'Seal', 'unit': 'pcs'},
        ]);
      }
      if (path == '/api/work-orders') {
        return json([
          order(
            request.url.queryParameters['status']!.startsWith('ISSUED')
                ? 76
                : 77,
            request.url.queryParameters['status']!.startsWith('ISSUED')
                ? 'IN_PROGRESS'
                : 'CLOSED',
          ),
        ]);
      }
      if (path == '/api/work-orders/76') {
        return json(order(76, 'IN_PROGRESS', full: true));
      }
      if (path.endsWith('/action')) {
        return json({'order': order(76, 'AI_REVIEW', full: true)});
      }
      if (path == '/api/uploads') {
        return json({'url': '/uploads/photo.jpg?signed=yes'}, 201);
      }
      throw StateError('Unexpected request: $path');
    };
    final storage = MemoryTokenStorage();
    await storage.write('jwt');
    session = AuthSession(
      storage: storage,
      client: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
    );
    await session.restore();
    repository = ApiExecutorRepository(
      actionStorage: MemoryPendingActionStorage(),
      api: ExecutorApi(session, referenceStorage: MemoryReferenceStorage()),
      draftStorage: drafts,
    );
  });
  tearDown(() async {
    repository.dispose();
    session.dispose();
    await directory.delete(recursive: true);
  });
  test(
    'FIFO restored from server events after a fresh repository is created',
    () async {
      handler = (request) async {
        if (request.url.path.endsWith('/fault-codes') ||
            request.url.path.endsWith('/materials')) {
          return json([]);
        }
        if (request.url.path == '/api/work-orders') {
          return json(
            request.url.queryParameters['status']!.startsWith('ISSUED')
                ? [order(76, 'QUEUED'), order(77, 'QUEUED')]
                : [],
          );
        }
        final id = int.parse(request.url.path.split('/').last);
        final data = order(id, 'QUEUED', full: true);
        data['events'] = [
          {
            'action': 'QUEUE',
            'toStatus': 'QUEUED',
            'createdAt': id == 76
                ? '2026-10-06T12:00:00Z'
                : '2026-10-06T11:00:00Z',
            'actor': {'fullName': 'Worker'},
            'comment': null,
          },
        ];
        return json(data);
      };
      await repository.refreshExecutor(5);
      expect(
        ExecutorOrderQueue(
          repository.assignedTo(5),
        ).queued.map((o) => o.number),
        [77, 76],
      );
      repository.dispose();
      repository = ApiExecutorRepository(
        actionStorage: MemoryPendingActionStorage(),
        api: ExecutorApi(session, referenceStorage: MemoryReferenceStorage()),
        draftStorage: drafts,
      );
      await repository.refreshExecutor(5);
      expect(
        ExecutorOrderQueue(
          repository.assignedTo(5),
        ).queued.map((o) => o.number),
        [77, 76],
      );
    },
  );

  test(
    'simultaneous ratings use separate caches and UTC custom range',
    () async {
      final month = Completer<http.Response>();
      handler = (request) async {
        if (request.url.queryParameters['period'] == 'month') {
          return month.future;
        }
        return json({'id': 5, 'score': 42, 'closed': 2});
      };
      final old = repository.loadExecutorRating(5);
      const shift = ExecutorRatingPeriod('shift');
      await repository.loadExecutorRating(5, period: shift);
      month.complete(json({'id': 5, 'score': 88, 'closed': 10}));
      await old;
      expect(repository.executorRating(5, period: shift)!.score, 42);
      expect(repository.executorRating(5)!.score, 88);
      final custom = ExecutorRatingPeriod.custom(
        DateTime.parse('2026-10-01T00:00:00+05:00'),
        DateTime.parse('2026-10-02T23:59:59.999+05:00'),
      );
      await repository.loadExecutorRating(5, period: custom);
      expect(requests.last.url.queryParameters, {
        'from': '2026-09-30T19:00:00.000Z',
        'to': '2026-10-02T18:59:59.999Z',
      });
    },
  );

  testWidgets('profile changes rating period through the selector', (
    tester,
  ) async {
    handler = (request) async => json({'id': 5, 'score': 79, 'closed': 12});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: ExecutorProfileScreen(store: repository, employeeId: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('executor-rating-period')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('За смену · 12 часов').last);
    await tester.pumpAndSettle();
    expect(requests.last.url.queryParameters['period'], 'shift');
    expect(find.text('За 30 дней'), findsNothing);
    expect(find.text('За смену · 12 часов'), findsOneWidget);
    await tester.tap(find.text('79.0'));
    await tester.pumpAndSettle();
    expect(find.text('За смену · 12 часов'), findsNWidgets(2));
    expect(find.text('За месяц'), findsNothing);
    expect(find.text('За 30 дней'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'own monthly rating loads once and retains last result on failure',
    () async {
      final pending = Completer<http.Response>();
      handler = (request) async {
        expect(request.url.path, '/api/reports/my-rating');
        expect(request.url.queryParameters, {'period': 'month'});
        expect(request.headers['authorization'], 'Bearer jwt');
        return pending.future;
      };
      final first = repository.loadExecutorRating(5);
      final second = repository.loadExecutorRating(5);
      pending.complete(
        json({
          'id': 5,
          'score': 79,
          'quality': '4.5',
          'onTimeRate': 0.8,
          'reworkRate': 0.1,
          'closed': 12,
          'explanation': 'Качество 4.5 из 5. Итого 79 из 100.',
        }),
      );
      final rating = await first;
      expect(await second, same(rating));
      expect(rating!.score, 79);
      expect(rating.quality, 4.5);
      expect(rating.onTimePercent, 80);
      expect(rating.reworkPercent, 10);
      expect(rating.completedCount, 12);
      expect(rating.explanation, contains('79 из 100'));
      expect(
        requests.where((r) => r.url.path.endsWith('/my-rating')),
        hasLength(1),
      );
      handler = (_) async => json({'error': 'Сервис временно недоступен'}, 500);
      await expectLater(
        repository.loadExecutorRating(5),
        throwsA(isA<ApiException>()),
      );
      expect(repository.executorRating(5), same(rating));
      expect(
        () => repository.loadExecutorRating(6),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('rating rejects another executor and invalid server score', () async {
    handler = (_) async => json({'id': 6, 'score': 80, 'closed': 1});
    await expectLater(
      repository.loadExecutorRating(5),
      throwsA(isA<ApiException>()),
    );
    expect(repository.executorRating(5), isNull);
    handler = (_) async => json({'id': 5, 'score': 101, 'closed': 1});
    await expectLater(repository.loadExecutorRating(5), throwsFormatException);
    expect(repository.executorRating(5), isNull);
  });
  testWidgets('profile displays server rating and retains it on refresh failure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    handler = (_) async => json({
      'id': 5,
      'score': 79,
      'quality': 4.5,
      'onTimeRate': 0.8,
      'reworkRate': 0.1,
      'closed': 12,
      'explanation': 'Итого 79 из 100.',
      'returnRate': 0.3,
      'unjustifiedRejects': 0,
      'points': {
        'quality': 40.5,
        'onTime': 20,
        'noReturns': 10.5,
        'volume': 6,
        'complexity': 2,
        'rejects': 0,
      },
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ExecutorProfileScreen(store: repository, employeeId: 5),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('79.0'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'compact rating');
    expect(find.text('4.5 / 5'), findsNothing);
    expect(find.text('80%'), findsNothing);
    expect(find.text('10%'), findsNothing);
    expect(find.text('Итого 79 из 100.'), findsNothing);
    await tester.ensureVisible(find.text('79.0'));
    await tester.tap(find.text('79.0'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'rating sheet');
    expect(find.text('Как считается рейтинг'), findsOneWidget);
    expect(find.text('4.5 / 5'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('Итого 79 из 100.'), findsNothing);
    expect(
      find.text(
        'Средняя оценка ваших работ — 4.5 из 5. Баллы за качество: 40.5 из 45.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'В срок выполнено 80% нарядов. Баллы за соблюдение сроков: 20 из 25.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '70% нарядов обошлись без доработок и повторных поломок в течение 7 дней. Баллы за надёжность ремонта: 10.5 из 15.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Вы закрыли 12 нарядов. Баллы за объём работы: 6 из 10.'),
      findsOneWidget,
    );
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(IconButton),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    handler = (_) async => json({'error': 'Сервис временно недоступен'}, 500);
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('79.0'), findsOneWidget);
    expect(find.text('Сервис временно недоступен'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
    'active and archive stay separate; failed refresh preserves both',
    () async {
      await repository.refreshExecutor(5);
      expect(repository.activeOrders.single.displayNumber, 'H-0076');
      expect(repository.historyOrders.single.displayNumber, 'H-0077');
      expect(repository.activeOrders.single.emergency, isTrue);
      final previous = handler;
      handler = (r) async =>
          r.url.queryParameters['status']?.contains('CLOSED') == true
          ? json({'error': 'Failed'}, 500)
          : await previous(r);
      await expectLater(
        repository.refreshExecutor(5),
        throwsA(isA<ApiException>()),
      );
      expect(repository.activeOrders.single.number, 76);
      expect(repository.historyOrders.single.number, 77);
    },
  );
  test(
    'compact refresh preserves loaded execution report and assessment',
    () async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      final previous = handler;
      handler = (request) async {
        if (request.url.path == '/api/work-orders/76') {
          return json({
            ...order(76, 'IN_PROGRESS', full: true),
            'completedAt': '2026-10-06T10:00:00Z',
            'actualDowntimeMinutes': 12,
            'aiAssessment': {
              'score': 82,
              'verdict': 'ACCEPTED',
              'explanation': 'Good',
            },
          });
        }
        return previous(request);
      };
      await repository.loadExecutorOrder(5, work);
      await repository.refreshExecutor(5);
      expect(work.completedWork, 'Completed');
      expect(work.faultCode, 'P-12 · Seal');
      expect(work.finishedAt?.toUtc(), DateTime.parse('2026-10-06T10:00:00Z'));
      expect(work.downtimeMinutes, 12);
      expect(work.assessment!.score, 82);
      expect(work.aiExplanation, 'Good');
    },
  );
  test(
    'detail loads before use; decimal strings and pause-aware clock map correctly',
    () async {
      await repository.refreshExecutor(5);
      final compact = repository.activeOrders.single;
      final loaded = await repository.loadExecutorOrder(5, compact);
      expect(loaded, same(compact));
      expect(loaded.detailsLoaded, isTrue);
      expect(loaded.normHours, 1.5);
      expect(loaded.materials, 'Seal · pcs: 1.5');
      expect(
        loaded.workDuration(DateTime.parse('2026-10-06T10:00:00Z')),
        const Duration(minutes: 40),
      );
      expect(requests.last.url.path, '/api/work-orders/76');
    },
  );
  test(
    'closed card loads pause-aware work time without downloading photos',
    () async {
      await repository.refreshExecutor(5);
      final previous = handler;
      handler = (request) async {
        if (request.url.path == '/api/work-orders/77') {
          final data = order(77, 'CLOSED', full: true);
          (data['events'] as List).add({
            'action': 'COMPLETE',
            'toStatus': 'AI_REVIEW',
            'createdAt': '2026-10-06T10:00:00Z',
            'actor': {'fullName': 'Worker'},
            'comment': null,
          });
          data['photos'] = [
            {'type': 'AFTER', 'fileUrl': '/uploads/not-downloaded.jpg'},
          ];
          return json(data);
        }
        return previous(request);
      };
      final compact = repository.historyOrders.single;
      final results = await Future.wait([
        repository.loadExecutorOrderTime(5, compact),
        repository.loadExecutorOrderTime(5, compact),
      ]);
      expect(results.first.detailsLoaded, isTrue);
      expect(
        results.first.workDuration(DateTime.parse('2026-10-07T10:00:00Z')),
        const Duration(minutes: 40),
      );
      expect(
        requests.where((r) => r.url.path == '/api/work-orders/77'),
        hasLength(1),
      );
      expect(requests.where((r) => r.url.path.startsWith('/uploads')), isEmpty);
      await repository.loadExecutorOrderTime(5, compact);
      expect(
        requests.where((r) => r.url.path == '/api/work-orders/77'),
        hasLength(1),
      );
    },
  );

  test(
    'pause uses server ID, UUID and comment; errors never change status',
    () async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      final previous = handler;
      final bodies = <Map>[];
      var attempts = 0;
      handler = (r) async {
        if (!r.url.path.endsWith('/action')) return previous(r);
        bodies.add(jsonDecode(r.body) as Map);
        attempts++;
        return attempts == 1
            ? json({'error': 'Failed'}, 500)
            : json({'order': order(76, 'PAUSED')});
      };
      await expectLater(
        repository.executorAction(
          5,
          work,
          OrderStatus.paused,
          reason: ' Break ',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(work.status, OrderStatus.working);
      await repository.executorAction(
        5,
        work,
        OrderStatus.paused,
        reason: ' Break ',
      );
      expect(bodies.first['action'], 'PAUSE');
      expect(bodies.first['comment'], 'Break');
      expect(bodies.first['clientActionId'], bodies.last['clientActionId']);
      expect(work.status, OrderStatus.paused);
    },
  );
  test(
    'failed COMPLETE keeps disk draft; retry reuses uploaded photo and action ID',
    () async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      final report = ExecutionDraft(
        work: 'Repair done',
        faultCode: repository.executorFaultCodes.single,
        materials: {repository.executorMaterials.single: 1.5},
        photos: [
          OrderPhoto(name: 'after.jpg', bytes: Uint8List.fromList([1, 2, 3])),
        ],
      );
      final previous = handler;
      final bodies = <Map>[];
      var attempts = 0;
      handler = (r) async {
        if (!r.url.path.endsWith('/action')) return previous(r);
        bodies.add(jsonDecode(r.body) as Map);
        attempts++;
        return attempts == 1
            ? json({'error': 'Report rejected'}, 500)
            : previous(r);
      };
      await expectLater(
        repository.submitExecution(5, work, report),
        throwsA(isA<ApiException>()),
      );
      expect(
        (await FileExecutionDraftStorage(
          directory: () async => directory,
        ).load(5, 76))!.work,
        'Repair done',
      );
      expect(work.status, OrderStatus.working);
      await repository.submitExecution(5, work, report);
      expect(bodies.last['faultCodeId'], 11);
      expect((bodies.last['materials'] as List).single, {
        'materialId': 23,
        'quantity': 1.5,
      });
      expect(bodies.last['afterPhotoUrls'], ['/uploads/photo.jpg?signed=yes']);
      expect(bodies.first['clientActionId'], bodies.last['clientActionId']);
      final uploads = requests
          .where((r) => r.url.path == '/api/uploads')
          .toList();
      expect(uploads.length, 1);
      expect(uploads.single.headers['Authorization'], 'Bearer jwt');
      expect(
        uploads.single.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(await drafts.load(5, 76), isNull);
      expect(repository.activeOrders.single.status, OrderStatus.review);
      expect(
        repository.historyOrders.map((o) => o.number),
        isNot(contains(76)),
      );
    },
  );
  for (final offline in [false, true]) {
    test(
      'COMPLETE added during sync waits for its own response; offline=$offline',
      () async {
        await repository.refreshExecutor(5);
        final work = repository.activeOrders.single;
        await repository.actionStorage.add(
          PendingAction(
            id: 'earlier-action',
            employeeId: 5,
            orderNumber: 76,
            type: 'workOrderAction',
            payload: {'action': 'START'},
            createdAt: repository.now,
          ),
        );
        final started = Completer<void>();
        final delayed = Completer<http.Response>();
        final previous = handler;
        var completes = 0;
        handler = (request) async {
          if (request.url.path.endsWith('/action')) {
            final body = jsonDecode(request.body) as Map;
            if (body['clientActionId'] == 'earlier-action') {
              started.complete();
              return delayed.future;
            }
            completes++;
            if (offline) throw http.ClientException('offline');
          }
          return previous(request);
        };
        final syncing = repository.syncPendingActions();
        await started.future;
        final submitting = repository.submitExecution(
          5,
          work,
          ExecutionDraft(
            work: 'Done',
            faultCode: repository.executorFaultCodes.single,
          ),
        );
        final submitted = offline
            ? expectLater(submitting, throwsA(isA<ApiException>()))
            : submitting;
        // Wait for the COMPLETE to reach durable storage while the old request is blocked.
        for (var i = 0; i < 100; i++) {
          if ((await repository.actionStorage.load()).length == 2) break;
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect((await repository.actionStorage.load()).length, 2);
        delayed.complete(json({'order': order(76, 'IN_PROGRESS')}));
        await syncing;
        await submitted;
        expect(completes, 1);
        if (offline) {
          expect((await drafts.load(5, 76))!.work, 'Done');
          expect(
            (await repository.actionStorage.load()).single.payload['action'],
            'COMPLETE',
          );
        } else {
          expect(await drafts.load(5, 76), isNull);
          expect(await repository.actionStorage.load(), isEmpty);
          expect(work.status, OrderStatus.review);
        }
      },
    );
  }
  test(
    'durable COMPLETE survives restart, keeps UUID and never uploads twice',
    () async {
      repository.dispose();
      final storage = FilePendingActionStorage(
        5,
        directory: () async => directory,
      );
      repository = ApiExecutorRepository(
        api: ExecutorApi(session, referenceStorage: MemoryReferenceStorage()),
        draftStorage: drafts,
        actionStorage: storage,
      );
      await repository.refreshExecutor(5);
      final previous = handler;
      final bodies = <Map>[];
      var fail = true;
      handler = (r) async {
        if (r.url.path.endsWith('/action')) {
          bodies.add(jsonDecode(r.body) as Map);
          if (fail) return json({'error': 'Unavailable'}, 503);
        }
        return previous(r);
      };
      await expectLater(
        repository.submitExecution(
          5,
          repository.activeOrders.single,
          ExecutionDraft(
            work: 'Done',
            faultCode: repository.executorFaultCodes.single,
            photos: [
              OrderPhoto(
                name: 'after.jpg',
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ],
          ),
        ),
        throwsA(isA<ApiException>()),
      );
      final saved = (await storage.load()).single;
      expect(saved.payload['afterPhotoUrls'], [
        '/uploads/photo.jpg?signed=yes',
      ]);
      repository.dispose();
      fail = false;
      repository = ApiExecutorRepository(
        api: ExecutorApi(session, referenceStorage: MemoryReferenceStorage()),
        draftStorage: drafts,
        actionStorage: FilePendingActionStorage(
          5,
          directory: () async => directory,
        ),
      );
      await repository.syncPendingActions();
      expect(bodies.map((b) => b['clientActionId']).toSet(), {saved.id});
      expect(requests.where((r) => r.url.path == '/api/uploads').length, 1);
      expect(await storage.load(), isEmpty);
      expect(await drafts.load(5, 76), isNull);
    },
  );

  test(
    'FIFO stops on network error; replay and permanent errors are removed',
    () async {
      repository.dispose();
      final storage = MemoryPendingActionStorage();
      repository = ApiExecutorRepository(
        api: ExecutorApi(session, referenceStorage: MemoryReferenceStorage()),
        draftStorage: drafts,
        actionStorage: storage,
      );
      await repository.refreshExecutor(5);
      for (var i = 0; i < 4; i++) {
        await storage.add(
          PendingAction(
            id: 'stable-uuid-$i',
            employeeId: 5,
            orderNumber: 76,
            type: 'workOrderAction',
            payload: {'action': 'PAUSE', 'comment': '$i'},
            createdAt: DateTime.utc(2026, 10, 6),
          ),
        );
      }
      final previous = handler;
      final sent = <String>[];
      var networkDown = true;
      handler = (r) async {
        if (!r.url.path.endsWith('/action')) return previous(r);
        final id = (jsonDecode(r.body) as Map)['clientActionId'] as String;
        sent.add(id);
        if (networkDown) {
          throw const SocketException('offline');
        }
        if (id.endsWith('0')) {
          return json({'order': order(76, 'IN_PROGRESS'), 'replayed': true});
        }
        if (id.endsWith('1')) return json({'error': 'Conflict'}, 409);
        if (id.endsWith('2')) return json({'error': 'Invalid data'}, 400);
        return json({'error': 'Forbidden'}, 403);
      };
      await expectLater(repository.syncPendingActions(), throwsA(anything));
      expect(sent, ['stable-uuid-0']);
      expect((await storage.load()).length, 4);
      networkDown = false;
      await expectLater(
        repository.syncPendingActions(),
        throwsA(isA<ApiException>()),
      );
      expect(sent.skip(1), [
        'stable-uuid-0',
        'stable-uuid-1',
        'stable-uuid-2',
        'stable-uuid-3',
      ]);
      expect(await storage.load(), isEmpty);
      expect(repository.loadError, contains('Forbidden'));
      expect(
        requests.any(
          (r) => r.method == 'GET' && r.url.path == '/api/work-orders/76',
        ),
        isTrue,
      );
    },
  );

  test(
    'executor notification API filters recipient and PATCH uses updated confirmation',
    () async {
      final previous = handler;
      handler = (request) async {
        if (request.url.path == '/api/notifications') {
          return json([
            {
              'id': 2,
              'userId': 5,
              'workOrderId': 773,
              'type': 'OVERDUE_3',
              'title': 'Server title',
              'message': 'Server body',
              'isRead': false,
              'createdAt': '2026-10-05T17:35:16.450Z',
            },
            {
              'id': 3,
              'userId': 99,
              'workOrderId': 773,
              'type': 'NOT_ACCEPTED',
              'title': 'Master notification about the same order',
              'message': 'Private',
              'isRead': false,
              'createdAt': '2026-10-05T17:36:16.450Z',
            },
          ]);
        }
        if (request.url.path == '/api/notifications/2/read') {
          expect(request.method, 'PATCH');
          expect(request.headers['Authorization'], 'Bearer jwt');
          return json({'updated': 1});
        }
        return previous(request);
      };
      await repository.loadNotification();
      expect(repository.notifications.single['id'], 2);
      expect(repository.notifications.single['message'], 'Server body');
      final count = requests.length;
      await expectLater(
        repository.markNotificationRead(3),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
      expect(requests.length, count);
      await repository.markNotificationRead(2);
      expect(repository.notifications.single['isRead'], isTrue);
    },
  );

  test('pagination collects active orders and history independently', () async {
    final previous = handler;
    handler = (r) async {
      if (r.url.path == '/api/work-orders/201') {
        return json(order(201, 'QUEUED', full: true));
      }
      if (r.url.path != '/api/work-orders') return previous(r);
      final active = r.url.queryParameters['status']!.startsWith('ISSUED');
      final offset = int.parse(r.url.queryParameters['offset']!);
      if (!active) return json([order(999, 'CLOSED')]);
      return json(
        offset == 0
            ? List.generate(200, (i) => order(i + 1, 'ISSUED'))
            : [order(201, 'QUEUED')],
      );
    };
    await repository.refreshExecutor(5);
    expect(repository.activeOrders.length, 201);
    expect(repository.historyOrders.single.number, 999);
    expect(
      requests.where((r) => r.url.queryParameters['offset'] == '200').length,
      1,
    );
  });
  test('409 refreshes detail; 404 removes inaccessible order', () async {
    await repository.refreshExecutor(5);
    final work = repository.activeOrders.single;
    final previous = handler;
    handler = (r) async {
      if (r.url.path.endsWith('/action')) {
        return json({'error': 'Status changed'}, 409);
      }
      if (r.url.path == '/api/work-orders/76') {
        return json(order(76, 'PAUSED', full: true));
      }
      return previous(r);
    };
    await expectLater(
      repository.executorAction(5, work, OrderStatus.paused, reason: 'Break'),
      throwsA(isA<ApiException>()),
    );
    expect(work.status, OrderStatus.paused);
    handler = (r) async => json({'error': 'Not found'}, 404);
    await expectLater(
      repository.loadExecutorOrder(5, work),
      throwsA(isA<ApiException>()),
    );
    expect(repository.activeOrders, isEmpty);
  });
  test(
    'null values stay unfilled; explicit zero stays zero; removed norm clears',
    () async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      final previous = handler;
      var empty = false;
      handler = (r) async {
        if (r.url.path != '/api/work-orders/76') return previous(r);
        return json({
          ...order(76, 'IN_PROGRESS', full: true),
          'normative': empty ? null : {'hours': '1.5'},
          'actualDowntimeMinutes': empty ? null : 0,
          'aiAssessment': empty
              ? null
              : {'verdict': 'ACCEPTED', 'score': '0', 'masterScore': null},
        });
      };
      await repository.loadExecutorOrder(5, work);
      expect(work.normHours, 1.5);
      expect(work.aiScore, 0);
      expect(work.downtimeMinutes, 0);
      empty = true;
      await repository.loadExecutorOrder(5, work);
      expect(work.normHours, isNull);
      expect(work.aiScore, isNull);
      expect(work.finalScore, isNull);
      expect(work.assessment, isNull);
      expect(work.downtimeMinutes, isNull);
      expect(repository.employee(5).grade, isNull);
      expect(AuthUser.fromJson({...user, 'grade': 0}).grade, 0);
    },
  );
  testWidgets('refresh preserves Russian server error in Kazakh interface', (
    tester,
  ) async {
    await repository.refreshExecutor(5);
    handler = (r) async => json({'error': 'Сервер временно недоступен'}, 503);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('kk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ExecutorScreen(store: repository, employeeId: 5),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Сервер временно недоступен'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final code in [403, 404]) {
    test('action $code removes order and prevents repeated requests', () async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      handler = (r) async => json({'error': 'Недоступный наряд'}, code);
      await expectLater(
        repository.executorAction(5, work, OrderStatus.paused, reason: 'Break'),
        throwsA(isA<ApiException>()),
      );
      expect(repository.activeOrders, isEmpty);
      expect(work.accessErrorStatus, code);
      expect(availableExecutorActions(work, 5), isEmpty);
      final count = requests.length;
      await expectLater(
        repository.executorAction(5, work, OrderStatus.paused, reason: 'Break'),
        throwsA(isA<ApiException>()),
      );
      expect(requests.length, count);
    });
  }
  test('failed detail refresh after 409 blocks stale action buttons', () async {
    await repository.refreshExecutor(5);
    final work = repository.activeOrders.single;
    final previous = handler;
    handler = (r) async => r.url.path.endsWith('/action')
        ? json({'error': 'Статус изменился'}, 409)
        : json({'error': 'Нет связи'}, 503);
    await expectLater(
      repository.executorAction(5, work, OrderStatus.paused, reason: 'Break'),
      throwsA(isA<ApiException>()),
    );
    expect(availableExecutorActions(work, 5), isEmpty);
    handler = previous;
    await repository.loadExecutorOrder(5, work);
    expect(work.accessErrorStatus, isNull);
    expect(availableExecutorActions(work, 5), contains('PAUSE'));
  });
  testWidgets(
    '400 keeps reason sheet open, preserves text and permits correction',
    (tester) async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      final previous = handler;
      var attempt = 0;
      handler = (r) async {
        if (!r.url.path.endsWith('/action')) return previous(r);
        if (++attempt == 1) {
          return json({
            'error': 'Уточните причину',
            'details': [
              {
                'path': ['comment'],
                'message': 'Опишите причину подробнее',
              },
            ],
          }, 400);
        }
        return json({'order': order(76, 'PAUSED', full: true)});
      };
      await tester.pumpWidget(
        MaterialApp(
          home: ExecutorOrderScreen(
            store: repository,
            order: work,
            employeeId: 5,
          ),
        ),
      );
      await tester.tap(find.text('Приостановить'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Жду');
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(find.text('Опишите причину подробнее'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Жду',
      );
      expect(work.status, OrderStatus.working);
      await tester.enterText(
        find.byType(TextFormField),
        'Жду запчасти со склада',
      );
      await tester.tap(find.text('Подтвердить'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(work.status, OrderStatus.paused);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('404 loader shows server error and removes retry button', (
    tester,
  ) async {
    await repository.refreshExecutor(5);
    final work = repository.activeOrders.single;
    handler = (r) async => json({'error': 'Наряд не найден'}, 404);
    await tester.pumpWidget(
      MaterialApp(
        home: ExecutorOrderLoader(
          store: repository,
          order: work,
          employeeId: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Наряд не найден'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
    expect(find.text('Назад'), findsOneWidget);
    expect(repository.activeOrders, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'photo size limit accepts boundary and blocks oversized upload before HTTP',
    () async {
      validatePhotoSize(maxPhotoBytes);
      final count = requests.length;
      await expectLater(
        session.uploadPhoto('large.jpg', Uint8List(maxPhotoBytes + 1)),
        throwsA(isA<PhotoTooLargeException>()),
      );
      expect(requests.length, count);
    },
  );
  test(
    'signed images need no JWT; unsigned local images use JWT; external images never receive it',
    () async {
      handler = (r) async => http.Response.bytes([1, 2, 3], 200);
      await session.downloadPhoto('/uploads/photo.jpg?exp=123&sig=original');
      expect(requests.last.headers.containsKey('Authorization'), isFalse);
      expect(requests.last.url.query, 'exp=123&sig=original');
      await session.downloadPhoto('/uploads/private.jpg');
      expect(requests.last.headers['Authorization'], 'Bearer jwt');
      await session.downloadPhoto('https://example.com/photo.jpg');
      expect(requests.last.headers.containsKey('Authorization'), isFalse);
    },
  );
  test('expired photo signature refetches order and preserves login', () async {
    await repository.refreshExecutor(5);
    final work = repository.activeOrders.single;
    final previous = handler;
    var detailCalls = 0;
    handler = (r) async {
      if (r.url.path == '/api/work-orders/76') {
        detailCalls++;
        return json({
          ...order(76, 'IN_PROGRESS', full: true),
          'photos': [
            {
              'type': 'AFTER',
              'fileUrl':
                  '/uploads/after.jpg?exp=123&sig=${detailCalls == 1 ? 'old' : 'fresh'}',
            },
          ],
        });
      }
      if (r.url.path == '/uploads/after.jpg') {
        expect(r.headers.containsKey('Authorization'), isFalse);
        return r.url.queryParameters['sig'] == 'old'
            ? json({'error': 'Expired signature'}, 401)
            : http.Response.bytes([1, 2, 3], 200);
      }
      return previous(r);
    };
    await repository.loadExecutorOrder(5, work);
    expect(detailCalls, 2);
    expect(work.afterImages.single.bytes, [1, 2, 3]);
    expect(session.authenticated, isTrue);
    expect(work.accessErrorStatus, isNull);
  });
  test(
    'multipart uses file field and image MIME; upload errors preserve error/details',
    () async {
      final previous = handler;
      handler = (r) async {
        if (r.url.path != '/api/uploads') return previous(r);
        expect(r.headers['Authorization'], 'Bearer jwt');
        expect(
          r.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(r.body, contains('name="file"; filename="after.png"'));
        expect(r.body.toLowerCase(), contains('content-type: image/png'));
        return json({
          'error': 'Ошибка загрузки фото',
          'details': {'file': 'Файл повреждён'},
        }, 400);
      };
      await expectLater(
        session.uploadPhoto('after.png', Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Ошибка загрузки фото')
              .having(
                (e) => e.fieldMessage('file'),
                'details',
                'Файл повреждён',
              ),
        ),
      );
    },
  );
  test(
    'server authenticity REWORK verdict is displayed instead of assuming review',
    () async {
      await repository.refreshExecutor(5);
      final work = repository.activeOrders.single;
      final previous = handler;
      handler = (r) async {
        if (!r.url.path.endsWith('/action')) return previous(r);
        return json({
          'order': order(76, 'REWORK', full: true),
          'assessment': {
            'verdict': 'REWORK',
            'score': 2,
            'explanation': 'Фото повторяет снимок другого наряда',
          },
        });
      };
      await repository.submitExecution(
        5,
        work,
        ExecutionDraft(
          work: 'Работы выполнены',
          faultCode: repository.executorFaultCodes.single,
        ),
      );
      expect(work.status, OrderStatus.rework);
      expect(
        work.assessment!.explanation,
        'Фото повторяет снимок другого наряда',
      );
    },
  );
  test('protected 401 expires session; image 401 does not', () async {
    final previous = handler;
    handler = (r) async => r.url.path == '/uploads/old.jpg'
        ? json({'error': 'Expired image'}, 401)
        : await previous(r);
    await expectLater(
      session.downloadPhoto('/uploads/old.jpg'),
      throwsA(isA<ApiException>()),
    );
    expect(session.authenticated, isTrue);
    handler = (r) async => json({'error': 'Expired token'}, 401);
    await expectLater(
      repository.refreshExecutor(5),
      throwsA(isA<ApiException>()),
    );
    expect(session.authenticated, isFalse);
  });
}
