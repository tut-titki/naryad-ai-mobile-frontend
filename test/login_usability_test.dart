import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/features/auth/data/auth_preferences_storage.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/auth/screens/login_screen.dart';
import 'package:mineral/features/auth/widgets/auth_scope.dart';
import 'package:mineral/l10n/app_localizations.dart';

AuthSession sessionWith(
  AuthPreferencesStorage preferences, {
  bool reject = false,
}) => AuthSession(
  storage: MemoryTokenStorage(),
  preferencesStorage: preferences,
  client: MockClient((request) async {
    if (reject) {
      return http.Response(
        jsonEncode({'error': 'Неверный номер телефона или пароль'}),
        401,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final user = {
      'id': 1,
      'fullName': 'Мастер',
      'role': 'MASTER',
      'phone': '+77012345678',
    };
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

Widget loginApp(AuthSession session) => AuthScope(
  session: session,
  child: MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const LoginScreen(),
    routes: {'/master': (_) => const Scaffold(body: Text('Рабочий экран'))},
  ),
);

void main() {
  test(
    'successful login remembers the phone across logout and restart',
    () async {
      final preferences = MemoryAuthPreferencesStorage();
      var session = sessionWith(preferences);
      await session.login('+7 701 234 56 78', 'password');
      await session.logout();
      session.dispose();
      session = sessionWith(preferences);
      expect(await session.loadLastPhone(), '+77012345678');
      expect(session.authenticatedWithPassword, isFalse);
      session.dispose();
    },
  );

  testWidgets('login prefills the saved phone and supports autofill', (
    tester,
  ) async {
    final preferences = MemoryAuthPreferencesStorage()..phone = '+77012345678';
    final session = sessionWith(preferences);
    await tester.pumpWidget(loginApp(session));
    await tester.pumpAndSettle();
    final phone = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(phone.controller!.text, '+7 701 234 56 78');
    expect(find.byType(AutofillGroup), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Рабочий экран'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('late saved phone does not overwrite manual input', (
    tester,
  ) async {
    final preferences = DelayedPhoneStorage();
    final session = sessionWith(preferences);
    await tester.pumpWidget(loginApp(session));
    await tester.enterText(find.byType(TextFormField).first, '+77098765432');
    preferences.result.complete('+77012345678');
    await tester.pumpAndSettle();
    final phone = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(phone.controller!.text, '+7 709 876 54 32');
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets(
    'editing after a failed login clears stale errors and keeps the saved phone',
    (tester) async {
      final preferences = MemoryAuthPreferencesStorage()
        ..phone = '+77012345678';
      final session = sessionWith(preferences, reject: true);
      await tester.pumpWidget(loginApp(session));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'wrong');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('Неверный номер телефона или пароль'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, 'corrected');
      await tester.pump();
      expect(find.text('Неверный номер телефона или пароль'), findsNothing);
      expect(preferences.phone, '+77012345678');
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
}

class DelayedPhoneStorage extends MemoryAuthPreferencesStorage {
  final result = Completer<String?>();
  @override
  Future<String?> readPhone() => result.future;
}
