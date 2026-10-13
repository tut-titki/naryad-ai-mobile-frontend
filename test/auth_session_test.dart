import 'package:mineral/features/references/data/reference_storage_stub.dart';
import 'package:mineral/features/auth/screens/change_password_screen.dart';
import 'package:mineral/features/auth/formatters/phone_input_formatter.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/app/app.dart';
import 'package:mineral/l10n/app_locale.dart';
import 'package:mineral/features/auth/widgets/auth_scope.dart';
import 'package:mineral/features/auth/screens/login_screen.dart';
import 'package:mineral/l10n/app_localizations.dart';
import 'support/pin_test_helpers.dart';

const profile = {
  'id': 5,
  'login': 'worker2',
  'phone': '+77012345678',
  'fullName': 'Исполнитель 2',
  'role': 'EXECUTOR',
  'language': 'kk',
  'specialty': 'Сварщик',
  'grade': 5,
  'brigadeId': 3,
  'isOnShift': true,
};
http.Response response(
  Object data,
  int code, {
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode(data),
  code,
  headers: {'content-type': 'application/json; charset=utf-8', ...headers},
);

void main() {
  for (final path in ['/api/auth/login', '/api/auth/me']) {
    test('logout cancels login while $path is pending', () async {
      final storage = MemoryTokenStorage();
      final started = Completer<void>();
      final delayed = Completer<http.Response>();
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          if (request.url.path == path) {
            started.complete();
            return delayed.future;
          }
          return response({'token': 'jwt', 'user': profile}, 200);
        }),
      );
      addTearDown(session.dispose);
      final failure = expectLater(
        session.login('+77012345678', 'secret12'),
        throwsA(isA<ApiException>()),
      );
      await started.future;
      await session.logout();
      delayed.complete(
        response(
          path.endsWith('/login') ? {'token': 'jwt', 'user': profile} : profile,
          200,
        ),
      );
      await failure;
      expect(session.authenticated, isFalse);
      expect(session.token, isNull);
      expect(await storage.read(), isNull);
    });
  }

  test('logout cancels pending session restoration', () async {
    final storage = MemoryTokenStorage();
    await storage.write('jwt');
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    final session = AuthSession(
      storage: storage,
      client: MockClient((_) async {
        started.complete();
        return delayed.future;
      }),
    );
    addTearDown(session.dispose);
    final restoring = session.restore();
    await started.future;
    await session.logout();
    delayed.complete(response(profile, 200));
    expect(await restoring, isNull);
    expect(session.user, isNull);
    expect(session.token, isNull);
    expect(await storage.read(), isNull);
  });

  for (final upload in [false, true]) {
    test(
      'stale ${upload ? 'upload' : 'request'} 401 preserves new login',
      () async {
        final storage = MemoryTokenStorage();
        await storage.write('old-jwt');
        final started = Completer<void>();
        final delayed = Completer<http.Response>();
        final session = AuthSession(
          storage: storage,
          client: MockClient((request) async {
            if (request.url.path == '/api/auth/me') {
              return response(profile, 200);
            }
            if (request.url.path == '/api/auth/login') {
              return response({'token': 'new-jwt', 'user': profile}, 200);
            }
            started.complete();
            return delayed.future;
          }),
        );
        addTearDown(session.dispose);
        await session.restore();
        final pending = upload
            ? session.uploadPhoto('photo.jpg', Uint8List.fromList([1, 2, 3]))
            : session.request('GET', '/api/work-orders');
        final failure = expectLater(
          pending,
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
        );
        await started.future;
        await session.login('+77012345678', 'secret12');
        delayed.complete(response({'error': 'Expired'}, 401));
        await failure;
        expect(session.authenticated, isTrue);
        expect(session.token, 'new-jwt');
        expect(await storage.read(), 'new-jwt');
      },
    );
  }

  test(
    'login sends documented payload, requests profile and saves JWT',
    () async {
      final storage = MemoryTokenStorage();
      final requests = <http.Request>[];
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/login')) {
            expect(jsonDecode(request.body), {
              'phone': '+7 701 234 56 78',
              'password': 'secret12',
            });
            expect(request.headers.containsKey('Authorization'), isFalse);
            return response({'token': 'test-jwt', 'user': profile}, 200);
          }
          expect(request.url.path, '/api/auth/me');
          expect(request.headers['Authorization'], 'Bearer test-jwt');
          return response(profile, 200);
        }),
      );
      addTearDown(session.dispose);
      final user = await session.login(' +7 701 234 56 78 ', 'secret12');
      expect(user.id, 5);
      expect(user.language, 'kk');
      expect(user.mobileRoute, '/executor');
      expect(await storage.read(), 'test-jwt');
      expect(requests.length, 2);
    },
  );

  test('empty password prevents network request', () async {
    final session = AuthSession(
      storage: MemoryTokenStorage(),
      client: MockClient((_) async => throw StateError('must not send')),
    );
    addTearDown(session.dispose);
    for (final password in ['']) {
      await expectLater(
        session.login('+77012345678', password),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    }
  });

  test(
    '401 login preserves message; 429 blocks even valid password using Retry-After',
    () async {
      var attempts = 0;
      final session = AuthSession(
        storage: MemoryTokenStorage(),
        client: MockClient((_) async {
          attempts++;
          if (attempts == 1) {
            return response({
              'error': 'Неверный номер телефона или пароль',
            }, 401);
          }
          return response(
            {'error': 'Слишком много попыток'},
            429,
            headers: {'retry-after': '900'},
          );
        }),
      );
      addTearDown(session.dispose);
      await expectLater(
        session.login('+77012345678', '0000'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Неверный номер телефона или пароль',
          ),
        ),
      );
      await expectLater(
        session.login('+77012345678', 'secret12'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.retryAfter,
            'retry',
            const Duration(minutes: 15),
          ),
        ),
      );
      await expectLater(
        session.login('+77012345678', 'secret12'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 429)),
      );
      expect(attempts, 2);
      expect(await session.restore(), isNull);
    },
  );

  test('restore checks me; protected 401 deletes stored JWT', () async {
    final storage = MemoryTokenStorage();
    await storage.write('existing-token');
    final session = AuthSession(
      storage: storage,
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer existing-token');
        return request.url.path == '/api/auth/me'
            ? response(profile, 200)
            : response({'error': 'Нужна авторизация'}, 401);
      }),
    );
    addTearDown(session.dispose);
    expect((await session.restore())!.id, 5);
    await expectLater(
      session.request('GET', '/api/work-orders'),
      throwsA(isA<ApiException>()),
    );
    expect(session.authenticated, isFalse);
    expect(await storage.read(), isNull);
  });

  test('logout unbinds push before removing JWT', () async {
    final storage = MemoryTokenStorage();
    await storage.write('existing-token');
    final session = AuthSession(
      storage: storage,
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/me') return response(profile, 200);
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/devices/device-token');
        expect(await storage.read(), 'existing-token');
        return http.Response('', 204);
      }),
    );
    addTearDown(session.dispose);
    await session.restore();
    session.pushToken = 'device-token';
    await session.logout();
    expect(await storage.read(), isNull);
    expect(session.user, isNull);
  });

  test('web-only role is rejected without saving a token', () async {
    final storage = MemoryTokenStorage();
    final session = AuthSession(
      storage: storage,
      client: MockClient(
        (_) async => response({
          'token': 'test-jwt',
          'user': {...profile, 'role': 'MANAGER'},
        }, 200),
      ),
    );
    addTearDown(session.dispose);
    await expectLater(
      session.login('+77012345678', 'secret12'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
    );
    expect(await storage.read(), isNull);
  });

  testWidgets(
    'API login has phone/password, no registration and timed 429 lock',
    (tester) async {
      final session = AuthSession(
        storage: MemoryTokenStorage(),
        client: MockClient(
          (_) async => response(
            {'error': 'Слишком много попыток'},
            429,
            headers: {'retry-after': '2'},
          ),
        ),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Номер телефона'), findsOneWidget);
      expect(find.text('Пароль'), findsOneWidget);
      expect(find.text('Создать аккаунт'), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, '7012345678');
      await tester.enterText(find.byType(TextFormField).last, 'secret12');
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.textContaining('Слишком много попыток'), findsOneWidget);
      // Use real clock expiry, then allow the periodic UI timer to refresh.
      session.blockedUntil = DateTime.now().subtract(
        const Duration(seconds: 1),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'restored executor uses actual employee ID; protected 401 returns to login',
    (tester) async {
      appLocale.value = const Locale('ru');
      addTearDown(() => appLocale.value = null);
      final storage = MemoryTokenStorage();
      await storage.write('existing-token');
      final startupRequests = <http.Request>[];
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          startupRequests.add(request);
          if (request.url.path == '/api/auth/me') {
            return response({...profile, 'id': 42, 'language': 'ru'}, 200);
          }
          if (request.url.queryParameters['compact'] == '1' ||
              request.url.path.startsWith('/api/references/')) {
            return response([], 200);
          }
          return response({'error': 'Нужна авторизация'}, 401);
        }),
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MainApp(
          session: session,
          referenceStorage: MemoryReferenceStorage(),
          pinRepository: testPinRepository(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(
        startupRequests.where((r) => r.url.path == '/api/auth/me'),
        hasLength(1),
      );
      expect(
        startupRequests.where((r) => r.url.path == '/api/work-orders'),
        hasLength(2),
      );
      expect(find.text('Мои наряды'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Создайте ПИН-код'), findsOneWidget);
      await enterPin(tester, '1234');
      await enterPin(tester, '1234');
      expect(find.text('Мои наряды'), findsOneWidget);
      expect(
        startupRequests.where((r) => r.url.path == '/api/auth/me'),
        hasLength(1),
      );
      expect(
        startupRequests.where((r) => r.url.path == '/api/work-orders'),
        hasLength(2),
      );
      expect(find.text('Исполнитель 2'), findsOneWidget);
      expect(find.text('Демонстрационные данные'), findsNothing);
      await expectLater(
        session.request('GET', '/api/work-orders'),
        throwsA(isA<ApiException>()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Вход'), findsOneWidget);
      expect(find.text('Номер телефона'), findsOneWidget);
      expect(await storage.read(), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
    },
  );
  test('login accepts legacy short and long passwords unchanged', () async {
    final sent = <String>[];
    final session = AuthSession(
      storage: MemoryTokenStorage(),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          final body = jsonDecode(request.body) as Map;
          expect(body.keys.toSet(), {'phone', 'password'});
          sent.add(body['password'] as String);
          return response({'token': 'jwt', 'user': profile}, 200);
        }
        return response(profile, 200);
      }),
    );
    addTearDown(session.dispose);
    final long = List.filled(129, 'x').join();
    await session.login('+77012345678', '1');
    await session.login('+77012345678', long);
    expect(sent, ['1', long]);
    expect(session.user!.phone, '+77012345678');
  });

  test('details accepts JSON-string field errors and plain messages', () {
    final error = ApiException(
      400,
      'Неверные данные',
      details: jsonEncode([
        {
          'path': ['phone'],
          'message': 'Неверный номер телефона',
        },
      ]),
    );
    expect(error.fieldMessage('phone'), 'Неверный номер телефона');
    expect(
      const ApiException(
        400,
        '',
        details: 'Неверный номер телефона',
      ).fieldMessage('phone'),
      'Неверный номер телефона',
    );
    expect(
      const ApiException(
        400,
        '',
        details: 'Пароль должен быть не короче 6 символов',
      ).fieldMessage('newPassword'),
      'Пароль должен быть не короче 6 символов',
    );
  });

  test(
    'change-password uses documented payload; 204 and 400 keep session',
    () async {
      var changeCount = 0;
      final storage = MemoryTokenStorage();
      await storage.write('jwt');
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/me') return response(profile, 200);
          expect(request.url.path, '/api/auth/change-password');
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer jwt');
          expect(jsonDecode(request.body), {
            'currentPassword': 'old',
            'newPassword': 'newSecret1',
          });
          changeCount++;
          if (changeCount == 1) {
            return response({'error': 'Текущий пароль указан неверно'}, 400);
          }
          return http.Response('', 204);
        }),
      );
      addTearDown(session.dispose);
      await session.restore();
      await expectLater(
        session.changePassword('old', 'newSecret1'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
      expect(session.authenticated, isTrue);
      await session.changePassword('old', 'newSecret1');
      expect(await storage.read(), 'jwt');
      expect(session.authenticated, isTrue);
    },
  );

  test(
    'API phone formatter preserves international numbers up to 15 digits',
    () {
      const formatter = ApiPhoneInputFormatter();
      for (final number in ['+44 7700 900123', '+1234567890123456']) {
        final input = TextEditingValue(
          text: number,
          selection: TextSelection.collapsed(offset: number.length),
        );
        expect(
          formatter.formatEditUpdate(TextEditingValue.empty, input).text,
          number == '+1234567890123456' ? '+123456789012345' : number,
        );
      }
    },
  );

  testWidgets(
    'phone details highlights phone; short legacy password reaches API',
    (tester) async {
      final session = AuthSession(
        storage: MemoryTokenStorage(),
        client: MockClient((request) async {
          expect(jsonDecode(request.body), {
            'phone': '+7 701 234 56 78',
            'password': '1',
          });
          return response({
            'error': 'Неверные данные',
            'details': jsonEncode([
              {
                'path': ['phone'],
                'message': 'Неверный номер телефона',
              },
            ]),
          }, 400);
        }),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, '7012345678');
      await tester.enterText(find.byType(TextFormField).last, '1');
      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();
      expect(find.text('Неверный номер телефона'), findsOneWidget);
      expect(find.text('Неверные данные'), findsNothing);
      expect(find.text('Вход'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'password screen validates new length and shows server field error',
    (tester) async {
      final storage = MemoryTokenStorage();
      await storage.write('jwt');
      var requests = 0;
      final session = AuthSession(
        storage: storage,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/me') return response(profile, 200);
          requests++;
          return response({
            'error': 'Неверные данные',
            'details': jsonEncode([
              {
                'path': ['newPassword'],
                'message': 'Пароль должен быть не короче 6 символов',
              },
            ]),
          }, 400);
        }),
      );
      addTearDown(session.dispose);
      await session.restore();
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: const ChangePasswordScreen(),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'old');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Изменить пароль'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(
        find.text('Пароль должен содержать от 6 до 128 символов'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).last, 'newSecret1');
      await tester.tap(find.text('Изменить пароль'));
      await tester.pumpAndSettle();
      expect(
        find.text('Пароль должен быть не короче 6 символов'),
        findsOneWidget,
      );
      expect(session.authenticated, isTrue);
      expect(await storage.read(), 'jwt');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
