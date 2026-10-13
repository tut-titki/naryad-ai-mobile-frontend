import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/core/theme/app_theme.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/auth/screens/change_password_screen.dart';
import 'package:mineral/features/auth/widgets/auth_scope.dart';
import 'package:mineral/features/master/screens/master_profile_screen.dart';
import 'package:mineral/features/master/screens/master_shell.dart';
import 'package:mineral/l10n/app_localizations.dart';

import 'helpers/backend_api_fixture.dart';

void main() {
  for (final width in [320.0, 1400.0]) {
    for (final language in ['ru', 'kk']) {
      testWidgets('master profile and account actions at $width in $language', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final session = AuthSession(storage: MemoryTokenStorage());
        session.user = AuthUser.fromJson({
          'id': 5,
          'fullName': 'Александр Иванов',
          'role': 'MASTER',
          'brigadeId': 3,
          'grade': 5,
          'isOnShift': true,
        });
        addTearDown(session.dispose);
        final api = testApi(
          handle: (request) async {
            if (request.url.path == '/api/references/brigades') {
              return jsonResponse([
                {'id': 2, 'name': 'Other brigade'},
                {'id': 3, 'name': 'Test brigade'},
              ]);
            }
            return null;
          },
        );
        addTearDown(api.dispose);

        await tester.pumpWidget(
          AuthScope(
            session: session,
            child: MaterialApp(
              locale: Locale(language),
              theme: buildAppTheme(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MasterShell(api: api),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          width < 1000
              ? find.byType(NavigationDestination).at(4)
              : find.byType(ListTile).at(4),
        );
        await tester.pumpAndSettle();

        final profile = find.byType(MasterProfileScreen);
        if (width < 1000) {
          final appBar = tester.widget<AppBar>(find.byType(AppBar));
          expect(appBar.backgroundColor, AppColors.primary);
          expect(appBar.foregroundColor, Colors.white);
          expect(
            (tester
                        .widget<DecoratedBox>(
                          find
                              .descendant(
                                of: find.byType(AppBar),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .gradient,
            AppColors.profileHeaderGradient,
          );
        }
        final s = AppLocalizations.of(tester.element(profile));
        expect(
          find.descendant(of: profile, matching: find.text('Александр Иванов')),
          findsOneWidget,
        );
        expect(find.text('АИ'), findsWidgets);
        expect(find.text('Test brigade'), findsOneWidget);
        expect(find.text('Other brigade'), findsNothing);
        expect(find.text(s.onShift), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(s.changePasswordTitle));
        await tester.pumpAndSettle();
        expect(find.byType(ChangePasswordScreen), findsOneWidget);
        Navigator.of(tester.element(find.byType(ChangePasswordScreen))).pop();
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.logout));
        await tester.pumpAndSettle();
        expect(find.text(s.logoutConfirmation), findsOneWidget);
        expect(session.user, isNotNull);
        await tester.tap(find.byKey(const ValueKey('logout-cancel')));
        await tester.pumpAndSettle();
        expect(session.user, isNotNull);
        expect(
          find.byKey(const ValueKey('logout-confirmation-sheet')),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('profile-logout')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('logout-confirm')));
        await tester.pumpAndSettle();
        expect(session.user, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
