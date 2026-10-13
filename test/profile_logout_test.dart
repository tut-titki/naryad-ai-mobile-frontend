import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/core/theme/app_theme.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/auth/widgets/auth_scope.dart';
import 'package:mineral/features/executor/screens/executor_profile_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'package:mineral/shared/data/demo_store.dart';

void main() {
  for (final language in ['ru', 'kk']) {
    testWidgets('executor logout requires confirmation in $language', (
      tester,
    ) async {
      var detachRequests = 0;
      final session = AuthSession(
        storage: MemoryTokenStorage(),
        client: MockClient((request) async {
          if (request.method == 'DELETE') {
            detachRequests++;
            return http.Response('', 204);
          }
          final user = {'id': 1, 'fullName': 'Исполнитель', 'role': 'EXECUTOR'};
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/login')
                  ? {'token': 'jwt', 'user': user}
                  : user,
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(session.dispose);
      await session.login('+77012345678', 'password');
      session.pushToken = 'registered-device-token';
      final store = DemoStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: MaterialApp(
            theme: buildAppTheme(),
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ExecutorProfileScreen(store: store, employeeId: 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final s = AppLocalizations.of(
        tester.element(find.byType(ExecutorProfileScreen)),
      );
      final logout = find.byKey(const ValueKey('profile-logout'));
      Future<void> openConfirmation() async {
        await tester.ensureVisible(logout);
        await tester.tap(logout);
        await tester.pumpAndSettle();
        expect(find.text(s.logoutConfirmation), findsOneWidget);
        expect(session.authenticated, isTrue);
        expect(detachRequests, 0);
      }

      await openConfirmation();
      await tester.tap(find.byKey(const ValueKey('logout-cancel')));
      await tester.pumpAndSettle();
      expect(session.authenticated, isTrue);

      await openConfirmation();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('logout-confirmation-sheet')),
        findsNothing,
      );
      expect(session.authenticated, isTrue);

      await openConfirmation();
      await tester.tapAt(const Offset(12, 12));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('logout-confirmation-sheet')),
        findsNothing,
      );
      expect(session.authenticated, isTrue);

      await openConfirmation();
      await tester.tap(find.byKey(const ValueKey('logout-confirm')));
      await tester.pumpAndSettle();
      expect(session.authenticated, isFalse);
      expect(detachRequests, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
