import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/auth/data/auth_session.dart' as auth;
import 'package:mineral/features/notifications/data/notifications_api.dart';
import 'package:mineral/features/notifications/screens/notifications_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'helpers/backend_api_fixture.dart';

NotificationApiModel notice(
  int id, {
  String type = 'NEW_ORDER',
  int? orderId,
  bool read = false,
}) => NotificationApiModel(
  id: id,
  userId: 5,
  workOrderId: orderId,
  type: type,
  title: 'Наряд $id',
  message: 'Сервер: просрочен на 45 мин. Статус в работе с 09:20.',
  isRead: read,
  createdAt: DateTime.utc(2026, 10, 5, 17, id),
);
Widget host(Widget child) => MaterialApp(
  locale: const Locale('kk'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

class NotificationSource extends ChangeNotifier {
  List<NotificationApiModel> items = [];
  void update(List<NotificationApiModel> next) {
    items = next;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'numbered overdue repeats group without merging escalation or orders',
    (tester) async {
      final reads = <int>[];
      await tester.pumpWidget(
        host(
          NotificationsScreen(
            standalone: true,
            load: () async => [
              notice(1, type: 'OVERDUE_318', orderId: 1551),
              notice(2, type: 'OVERDUE_319', orderId: 1551),
              notice(3, type: 'LONG_OVERDUE_320', orderId: 1551),
              notice(4, type: 'OVERDUE_321', orderId: 1552),
            ],
            markRead: (id) async => reads.add(id),
            onOrder: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('Наряд 1'), findsNothing);
      expect(find.text('Наряд 3'), findsOneWidget);
      expect(find.text('Наряд 4'), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.text('Наряд 1'), findsOneWidget);
      expect(find.text('Наряд 2'), findsNWidgets(2));
      await tester.tap(find.text('Барлығын оқу'));
      await tester.pumpAndSettle();
      expect(reads, [4, 3, 2, 1]);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'master API rejects an unconfirmed read instead of reporting success',
    () async {
      final api = testApi(handle: (_) async => jsonResponse({'updated': 0}));
      addTearDown(api.dispose);
      await expectLater(api.notifications.markRead(2), throwsException);
    },
  );
  testWidgets('read all marks unread only and pull refresh remains available', (
    tester,
  ) async {
    var items = [notice(1), notice(2), notice(3, read: true)];
    final reads = <int>[];
    var loads = 0;
    await tester.pumpWidget(
      host(
        NotificationsScreen(
          standalone: true,
          load: () async {
            loads++;
            return items;
          },
          markRead: (id) async {
            reads.add(id);
            items = items
                .map((item) => item.id == id ? item.asRead() : item)
                .toList();
          },
          onOrder: (_) => fail('Reading all must not navigate'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Барлығын оқу'));
    await tester.pumpAndSettle();
    expect(reads, [2, 1]);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    final before = loads;
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(loads, greaterThan(before));
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read all updates every card before the first network response', (
    tester,
  ) async {
    final pending = Completer<void>();
    final reads = <int>[];
    await tester.pumpWidget(
      host(
        NotificationsScreen(
          standalone: true,
          load: () async => [notice(1), notice(2)],
          markRead: (id) async {
            reads.add(id);
            if (id == 2) await pending.future;
          },
          onOrder: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Барлығын оқу'));
    await tester.pump();
    expect(reads, [2]);
    for (final id in [1, 2]) {
      expect(
        tester.widget<Text>(find.text('Наряд $id')).style?.fontWeight,
        FontWeight.w500,
      );
    }
    pending.complete();
    await tester.pumpAndSettle();
    expect(reads, [2, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read all preserves unread items on failure', (tester) async {
    await tester.pumpWidget(
      host(
        NotificationsScreen(
          standalone: true,
          load: () async => [notice(1), notice(2)],
          markRead: (id) async {
            if (id == 1) throw const auth.ApiException(503, 'Нет связи');
          },
          onOrder: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Барлығын оқу'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Наряд 1')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('Наряд 2')).style?.fontWeight,
      FontWeight.w500,
    );
    expect(find.text('Нет связи'), findsOneWidget);
  });

  testWidgets(
    'standalone sorts latest first, groups prefixes and preserves server text',
    (tester) async {
      await tester.pumpWidget(
        host(
          NotificationsScreen(
            standalone: true,
            load: () async => [notice(1), notice(2, type: 'LONG_OVERDUE_4')],
            markRead: (_) async {},
            onOrder: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Наряд 2')).dy,
        lessThan(tester.getTopLeft(find.text('Наряд 1')).dy),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text(notice(1).message), findsNWidgets(2));
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('read without work order works; unknown types remain visible', (
    tester,
  ) async {
    var reads = 0;
    var opens = 0;
    var item = notice(1, type: 'FUTURE_TYPE');
    await tester.pumpWidget(
      host(
        NotificationsScreen(
          standalone: true,
          load: () async => [item],
          markRead: (id) async {
            reads++;
            item = item.asRead();
          },
          onOrder: (_) => opens++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(item.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item.title));
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(opens, 0);
    expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'duplicate tap cannot duplicate PATCH or opening; role callback gets API ID',
    (tester) async {
      final completion = Completer<void>();
      var reads = 0;
      final opened = <int>[];
      await tester.pumpWidget(
        host(
          NotificationsScreen(
            standalone: true,
            load: () async => [notice(2, orderId: 773)],
            markRead: (_) {
              reads++;
              return completion.future;
            },
            onOrder: (id) => opened.add(id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Наряд 2'));
      await tester.pump();
      await tester.tap(find.text('Наряд 2'));
      expect(reads, 1);
      completion.complete();
      await tester.pumpAndSettle();
      expect(opened, [773]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed read preserves unread state and still opens order', (
    tester,
  ) async {
    final opened = <int>[];
    await tester.pumpWidget(
      host(
        NotificationsScreen(
          standalone: true,
          load: () async => [notice(2, orderId: 773)],
          markRead: (_) async =>
              throw const auth.ApiException(503, 'Нет связи'),
          onOrder: (id) => opened.add(id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Наряд 2'));
    await tester.pumpAndSettle();
    expect(opened, [773]);
    expect(find.text('Нет связи'), findsOneWidget);
    final title = tester.widget<Text>(find.text('Наряд 2'));
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live source survives stale GET; cached notifications survive network failure',
    (tester) async {
      final source = NotificationSource()..items = [notice(1)];
      final fetch = Completer<List<NotificationApiModel>>();
      var loads = 0;
      addTearDown(source.dispose);
      await tester.pumpWidget(
        host(
          NotificationsScreen(
            standalone: true,
            source: source,
            snapshot: () => source.items,
            load: () {
              loads++;
              return fetch.future;
            },
            markRead: (_) async {},
            onOrder: (_) {},
          ),
        ),
      );
      await tester.pump();
      source.update([notice(2), notice(1)]);
      await tester.pump();
      fetch.complete([notice(1)]);
      await tester.pumpAndSettle();
      expect(find.text('Наряд 2'), findsOneWidget);
      expect(loads, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        host(
          NotificationsScreen(
            standalone: true,
            source: source,
            snapshot: () => source.items,
            load: () async => throw const auth.ApiException(503, 'Нет связи'),
            markRead: (_) async {},
            onOrder: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Наряд 2'), findsOneWidget);
      expect(find.text('Нет связи'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
