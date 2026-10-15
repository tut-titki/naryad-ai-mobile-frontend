import 'package:mineral/shared/widgets/app_bottom_sheet.dart';
import 'package:mineral/core/utils/enterprise_time.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/api/api_client.dart';
import 'package:mineral/features/master/screens/dashboard_screen.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/features/orders/screens/order_detail_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'helpers/backend_api_fixture.dart';

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('editing deadline keeps the displayed enterprise time', (
    tester,
  ) async {
    final tomorrow = enterpriseTime(
      DateTime.now(),
    ).add(const Duration(days: 1));
    final deadline = enterpriseWallTimeToUtc(tomorrow, 21, 14);
    Map<String, dynamic>? sent;
    final api = testApi(
      handle: (request) async {
        if (request.url.path == '/api/work-orders/773') {
          if (request.method == 'PATCH') {
            sent = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return jsonResponse(
            orderJson()..['deadline'] = deadline.toIso8601String(),
          );
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrderDetailScreen(api: api, orderId: 773),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Изменить'));
    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.event_outlined));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .initialDate!
          .day,
      tomorrow.day,
    );
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    final timeFields = find.byType(DropdownButtonFormField<int>);
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(timeFields.first)
          .initialValue,
      21,
    );
    expect(
      tester.widget<DropdownButtonFormField<int>>(timeFields.last).initialValue,
      14,
    );
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(DateTime.parse(sent!['deadline'] as String), deadline);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master changes AI score and sends it with CLOSE', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    final api = testApi(
      handle: (request) async {
        if (request.url.path == '/api/work-orders/773/action') {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse({'order': orderJson(status: 'CLOSED')});
        }
        if (request.url.path == '/api/work-orders/773') {
          return jsonResponse(
            orderJson(status: 'AI_REVIEW')
              ..['aiAssessment'] = {
                'verdict': 'ACCEPTED_WITH_COMMENTS',
                'score': 3,
                'masterScore': null,
              },
          );
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrderDetailScreen(api: api, orderId: 773),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Принять и закрыть'));
    await tester.tap(find.text('Принять и закрыть'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AppSheetContent);
    expect(
      find.descendant(of: dialog, matching: find.byIcon(Icons.star)),
      findsNWidgets(3),
    );
    await tester.tap(find.byTooltip('2'));
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Закрыть наряд')),
    );
    await tester.pumpAndSettle();
    expect(sent!['action'], 'CLOSE');
    expect(sent!['masterScore'], 2);
    expect(sent!['clientActionId'], isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  test(
    'binary report export and failed upload use shared client without retries',
    () async {
      var uploads = 0;
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0xff]);
      final api = testApi(
        handle: (request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          if (request.url.path == '/api/reports/export.pdf') {
            return http.Response.bytes(bytes, 200);
          }
          if (request.url.path == '/api/uploads') {
            uploads++;
            expect(
              request.headers['content-type'],
              contains('multipart/form-data'),
            );
            return jsonResponse({'message': 'Upload failed'}, status: 500);
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      expect(await api.reports.export(pdf: true), bytes);
      await expectLater(
        api.uploads.uploadPhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'photo.jpg',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(uploads, 1);
    },
  );

  test('orders pagination fetches records beyond the first 500', () async {
    final offsets = <String?>[];
    final api = testApi(
      handle: (request) async {
        offsets.add(request.url.queryParameters['offset']);
        return jsonResponse(
          request.url.queryParameters['offset'] == '0'
              ? List.generate(500, (index) => orderJson(id: index + 1))
              : [orderJson(id: 501)],
        );
      },
    );
    addTearDown(api.dispose);
    final orders = await api.workOrders.getAllWorkOrders();
    expect(orders.length, 501);
    expect(offsets, ['0', '500']);
  });

  testWidgets(
    'expired signed photo refreshes GET and preserves new URL and headers',
    (tester) async {
      var gets = 0;
      final api = testApi(
        handle: (request) async {
          if (request.url.path == '/api/work-orders/773') {
            gets++;
            final order = orderJson()
              ..['photos'] = [
                {
                  'id': 1,
                  'type': 'BEFORE',
                  'fileUrl':
                      '/uploads/photo?exp=123&sig=${gets == 1 ? 'old' : 'new'}',
                },
              ];
            return jsonResponse(order);
          }
          return null;
        },
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OrderDetailScreen(api: api, orderId: 773),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Image).first);
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image).first);
      final network = image.image as NetworkImage;
      expect(network.url, 'https://backend.test/uploads/photo?exp=123&sig=old');
      expect(network.headers, isNull);
      image.errorBuilder!(
        tester.element(find.byType(Image).first),
        NetworkImageLoadException(statusCode: 401, uri: Uri.parse(network.url)),
        null,
      );
      await tester.pumpAndSettle();
      expect(gets, 2);
      final refreshed =
          tester.widget<Image>(find.byType(Image).first).image as NetworkImage;
      expect(
        refreshed.url,
        'https://backend.test/uploads/photo?exp=123&sig=new',
      );
      expect(refreshed.headers, isNull);
      expect(gets, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('order report loads the real report endpoint', (tester) async {
    var reports = 0;
    final api = testApi(
      handle: (request) async {
        if (request.url.path == '/api/reports/work-order/773') {
          reports++;
          return jsonResponse({'description': 'Server report'});
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrderDetailScreen(api: api, orderId: 773),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Отчёт по наряду'));
    await tester.pumpAndSettle();
    expect(reports, 1);
    expect(find.textContaining('Server report'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'status rules use backend contract, including REJECTED reassignment',
    () {
      for (final status in WorkOrderStatus.values) {
        expect(
          status.canCancel,
          [
            'ISSUED',
            'ACCEPTED',
            'QUEUED',
            'IN_PROGRESS',
            'PAUSED',
            'REWORK',
          ].contains(status.apiValue),
        );
        expect(
          status.canReassign,
          ![
            'COMPLETED',
            'AI_REVIEW',
            'CLOSED',
            'CANCELLED',
          ].contains(status.apiValue),
        );
      }
      for (final status in ['CLOSED', 'CANCELLED', 'REJECTED', 'AI_REVIEW']) {
        final json = orderJson(status: status)
          ..['deadline'] = '2000-01-01T00:00:00Z';
        expect(
          WorkOrderApiModel.fromJson(json).isOverdue,
          status == 'AI_REVIEW',
        );
      }
    },
  );

  test('API services preserve bearer auth, history and export bytes', () async {
    final requests = <String>[];
    final api = testApi(
      handle: (request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        requests.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/assistant/chat') {
          expect(jsonDecode(request.body), {'message': 'Who is available?'});
          return jsonResponse({
            'answer': 'Backend answer',
            'intent': 'availability',
            'data': [],
          });
        }
        if (request.url.path == '/api/assistant/history') {
          return jsonResponse({
            'unfamiliar': [
              null,
              {'text': 'History'},
            ],
          });
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    expect(
      (await api.assistant.chat('Who is available?')).answer,
      'Backend answer',
    );
    expect((await api.assistant.getHistory()).isEmpty, false);
    await expectLater(api.assistant.chat('x'), throwsA(isA<ApiException>()));
    for (final call in [
      api.reports.getShift,
      api.reports.getRatings,
      api.reports.getBrigadeRatings,
      api.reports.getMaterials,
      api.reports.getDowntime,
    ]) {
      await call();
    }
    expect(
      requests,
      containsAll([
        'GET /api/reports/shift',
        'GET /api/reports/ratings',
        'GET /api/reports/brigade-ratings',
        'GET /api/reports/materials',
        'GET /api/reports/downtime',
      ]),
    );
  });

  testWidgets('dashboard shows error and retry without fabricated metrics', (
    tester,
  ) async {
    var failed = true;
    var dashboardGets = 0;
    final api = testApi(
      handle: (request) async {
        if (request.url.path == '/api/work-orders/board') {
          dashboardGets++;
          return failed
              ? jsonResponse({'message': 'Analytics unavailable'}, status: 503)
              : jsonResponse(
                  boardJson()
                    ..['counters'] = {
                      'issued': 14,
                      'completed': 9,
                      'overdue': 2,
                      'equipmentInDowntime': 1,
                    },
                );
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(host(DashboardScreen(api: api, onOrder: (_) {})));
    await tester.pumpAndSettle();
    expect(find.text('Analytics unavailable'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    failed = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.text('17'), findsNothing);
    expect(find.text('Активные наряды'), findsNothing);
    expect(find.text('Средняя реакция, мин.'), findsNothing);
    expect(find.text('Среднее выполнение, мин.'), findsNothing);
    api.realtime.invalidate();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(dashboardGets, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('assistant sends once, retains failed text and retries', (
    tester,
  ) async {
    final pending = Completer<void>();
    var posts = 0;
    final api = testApi(
      handle: (request) async {
        if (request.url.path == '/api/assistant/chat') {
          posts++;
          if (posts == 1) {
            await pending.future;
            return jsonResponse({'message': 'Try again'}, status: 503);
          }
          return jsonResponse({
            'answer': 'Real backend reply',
            'intent': 'test',
            'data': null,
          });
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(host(AiScreen(api: api, onOrder: (_) {})));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Who is free?');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.tap(find.widgetWithText(FilledButton, 'Отправить'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Отправить'))
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Real backend reply'), findsOneWidget);
    expect(posts, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unknown notification type survives; read reloads and opens ID', (
    tester,
  ) async {
    var read = false;
    var gets = 0;
    int? opened;
    final api = testApi(
      handle: (request) async {
        if (request.url.path == '/api/notifications/2/read') {
          read = true;
          return jsonResponse({'updated': 1});
        }
        if (request.url.path == '/api/notifications') {
          gets++;
          return jsonResponse([
            {
              'id': 2,
              'userId': 5,
              'workOrderId': 773,
              'type': 'LONG_OVERDUE_99',
              'title': 'Notification from server',
              'message': 'Attention',
              'isRead': read,
              'createdAt': '2026-10-01T00:00:00Z',
            },
          ]);
        }
        return null;
      },
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      host(NotificationsScreen(api: api, onOrder: (id) => opened = id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notification from server'));
    await tester.pumpAndSettle();
    expect(read, true);
    expect(opened, 773);
    expect(gets, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mobile shell offers backend pages and profile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = testApi();
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MasterShell(api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('ИИ'), findsNothing);
    expect(find.text('Команда'), findsNothing);
    expect(find.text('Вся команда →'), findsNothing);
    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byType(NavigationDestination).at(index));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
