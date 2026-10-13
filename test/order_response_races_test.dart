import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/executor/data/api_executor_repository.dart';
import 'package:mineral/features/executor/data/executor_api.dart';
import 'package:mineral/features/executor/data/pending_action_storage.dart';
import 'package:mineral/features/executor/models/executor_order_dto.dart';
import 'package:mineral/features/orders/screens/order_screens.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:mineral/shared/models/models.dart';
import 'helpers/backend_api_fixture.dart';
import 'order_draft_restoration_test.dart' show NoPhotos;
import 'api_executor_repository_test.dart' show user, order, json;

void main() {
  for (final scenario in [
    'older',
    'newer',
    'equal',
    'missing',
    'refresh fails',
    'session ended',
    'access revoked',
  ]) {
    test(
      'action acknowledgement handles concurrent state: $scenario',
      () async {
        final reply = Completer<http.Response>();
        final started = Completer<void>();
        final tokens = MemoryTokenStorage();
        var detailReads = 0;
        var actionCalls = 0;
        await tokens.write('jwt');
        final session = AuthSession(
          storage: tokens,
          client: MockClient((r) async {
            if (r.url.path.endsWith('/auth/me')) return json(user);
            if (r.url.path.endsWith('/action')) {
              actionCalls++;
              started.complete();
              return reply.future;
            }
            detailReads++;
            if (scenario == 'access revoked' && detailReads > 1) {
              return json({'error': 'Reassigned'}, 403);
            }
            if (scenario == 'refresh fails' && detailReads > 2) {
              return json({'error': 'Unavailable'}, 503);
            }
            return json({
              ...order(76, 'IN_PROGRESS'),
              'updatedAt': detailReads == 1
                  ? '2026-10-06T10:00:00Z'
                  : scenario == 'equal'
                  ? '2026-10-06T11:00:00Z'
                  : '2026-10-06T12:00:00Z',
              'events': <Object>[],
            });
          }),
        );
        await session.restore();
        final repo = ApiExecutorRepository(
          api: ExecutorApi(session, referenceStorage: MemoryReferenceStorage()),
          actionStorage: MemoryPendingActionStorage(),
        );
        addTearDown(repo.dispose);
        addTearDown(session.dispose);
        final work = ExecutorOrderDto.fromJson(
          order(76, 'IN_PROGRESS'),
        ).toWorkOrder();
        await repo.loadExecutorOrder(5, work);
        final sending = repo.executorAction(
          5,
          work,
          OrderStatus.paused,
          reason: 'Break',
        );
        await started.future;
        if (scenario == 'access revoked') {
          await expectLater(
            repo.loadExecutorOrder(5, work),
            throwsA(isA<ApiException>()),
          );
        } else {
          await repo.loadExecutorOrder(5, work);
        }
        expect(work.status, OrderStatus.working);
        if (scenario == 'session ended') await session.expire();
        final actionOrder = {
          ...order(76, 'PAUSED'),
          'updatedAt': scenario == 'newer'
              ? '2026-10-06T13:00:00Z'
              : '2026-10-06T11:00:00Z',
        };
        if (scenario == 'missing' || scenario == 'refresh fails') {
          actionOrder.remove('updatedAt');
        }
        reply.complete(json({'order': actionOrder}));
        await sending;
        expect(
          work.status,
          scenario == 'newer' ? OrderStatus.paused : OrderStatus.working,
        );
        expect(actionCalls, 1);
        expect(await repo.actionStorage.load(), isEmpty);
        if (scenario == 'access revoked') {
          expect(work.accessErrorStatus, 403);
          expect(repo.activeOrders, isEmpty);
        }
      },
    );
  }

  testWidgets('old create acknowledgement preserves a newly opened draft', (
    tester,
  ) async {
    const key = 'order-draft:https://backend.test:test';
    final storage = MemoryReferenceStorage();
    await storage.write(key, [
      {
        'equipmentId': 2,
        'description': 'Old repair',
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
    Future<void> mount(int screen) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateOrderScreen(
            key: ValueKey(screen),
            api: api,
            draftStorage: storage,
            photoPicker: NoPhotos(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await mount(1);
    await tester.tap(find.byKey(const ValueKey('issue-order')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(posted, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await mount(2);
    await tester.enterText(
      find.byKey(const ValueKey('order-description')),
      'New repair',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect((await storage.read(key))!.single['description'], 'New repair');
    reply.complete(jsonResponse(orderJson(), status: 201));
    await tester.pumpAndSettle();
    final disk = await storage.read(key);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(disk, isNotEmpty, reason: 'Only the submitted draft may be cleared');
    expect(disk!.single['description'], 'New repair');
  });
}
