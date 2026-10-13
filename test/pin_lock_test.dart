import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mineral/features/auth/data/auth_session.dart';
import 'package:mineral/features/auth/data/auth_preferences_storage.dart';
import 'package:mineral/features/auth/data/pin_lock_controller.dart';
import 'package:mineral/features/auth/data/pin_repository.dart';
import 'package:mineral/features/auth/data/pin_storage.dart';
import 'package:mineral/features/auth/widgets/pin_lock_gate.dart';
import 'package:mineral/l10n/app_localizations.dart';

import 'support/pin_test_helpers.dart';

AuthSession testSession({
  TokenStorage? storage,
  AuthPreferencesStorage? preferencesStorage,
  int id = 1,
}) => AuthSession(
  baseUrl: 'https://backend.test',
  storage: storage ?? MemoryTokenStorage(),
  preferencesStorage: preferencesStorage,
  client: MockClient((request) async {
    final profile = {'id': id, 'fullName': 'Мастер', 'role': 'MASTER'};
    return http.Response(
      jsonEncode(
        request.url.path.endsWith('/login')
            ? {'token': 'jwt', 'user': profile}
            : profile,
      ),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }),
);

Future<void> settleController(PinLockController controller) async {
  for (var i = 0; i < 20 && controller.status == PinLockStatus.loading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Widget app(PinLockController controller, {DateTime Function()? now}) =>
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (_, child) =>
      PinLockGate(controller: controller, now: now, child: child!),
      home: const Scaffold(body: TextField(key: ValueKey('private-field'))),
    );

void main() {
  test(
    'background lock during forgotten-PIN logout cannot reset the old PIN',
    () async {
      final preferences = DelayedResetPreferences();
      final session = testSession(preferencesStorage: preferences);
      final repo = testPinRepository();
      await repo.create('https://backend.test|1', '1234');
      final controller = PinLockController(session: session, repository: repo);
      await session.login('+77012345678', 'password');
      await settleController(controller);
      controller.lock();
      await settleController(controller);
      final leaving = controller.forgotPin();
      await Future<void>.delayed(Duration.zero);
      controller.lock();
      await settleController(controller);
      expect(await repo.read('https://backend.test|1'), isNotNull);
      expect(preferences.pinResetAccount, 'https://backend.test|1');
      preferences.saved.complete();
      await leaving;
      expect(session.authenticated, isFalse);
      expect(await repo.read('https://backend.test|1'), isNotNull);
      controller.dispose();
      session.dispose();
    },
  );

  test(
    'password login skips an existing PIN, even with the same token',
    () async {
      final session = testSession();
      final repo = testPinRepository();
      await repo.create('https://backend.test|1', '1234');
      final controller = PinLockController(session: session, repository: repo);
      await session.login('+77012345678', 'password');
      await settleController(controller);
      expect(controller.canAccess, isTrue);
      controller.lock();
      await settleController(controller);
      expect(controller.canAccess, isFalse);
      await session.refreshUser();
      expect(controller.canAccess, isFalse);
      await session.login('+77012345678', 'password');
      await settleController(controller);
      expect(controller.canAccess, isTrue);
      await session.restore();
      await settleController(controller);
      expect(controller.status, PinLockStatus.unlock);
      // A fresh controller on startup must require PIN after restoration.
      controller.dispose();
      final restored = PinLockController(session: session, repository: repo);
      await settleController(restored);
      expect(restored.status, PinLockStatus.unlock);
      restored.dispose();
      session.dispose();
    },
  );

  testWidgets('PIN confirmation lets the user choose another code', (
    tester,
  ) async {
    final session = testSession();
    final repo = testPinRepository();
    final controller = PinLockController(session: session, repository: repo);
    await tester.pumpWidget(app(controller));
    await session.login('+77012345678', 'password');
    await tester.pumpAndSettle();
    await enterPin(tester, '1234');
    await tester.tap(find.byKey(const ValueKey('pin-change')));
    await tester.pump();
    expect(find.text('Создайте ПИН-код'), findsOneWidget);
    await enterPin(tester, '5678');
    await enterPin(tester, '5678');
    expect(controller.canAccess, isTrue);
    expect(
      (await repo.verify('https://backend.test|1', '5678')).status,
      PinVerificationStatus.matched,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    session.dispose();
  });

  testWidgets('short background visits preserve access and PIN confirmation', (
    tester,
  ) async {
    final session = testSession();
    final repo = testPinRepository();
    var now = DateTime(2026, 10, 13, 12);
    final controller = PinLockController(session: session, repository: repo);
    await tester.pumpWidget(app(controller, now: () => now));
    await session.login('+77012345678', 'password');
    await tester.pumpAndSettle();
    await enterPin(tester, '1234');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byKey(const ValueKey('pin-privacy-cover')), findsOneWidget);
    now = now.add(const Duration(seconds: 59));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Повторите ПИН-код'), findsOneWidget);
    await enterPin(tester, '1234');
    expect(controller.canAccess, isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('private-field')),
      'Черновик',
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Черновик'), findsNothing);
    now = now.add(const Duration(seconds: 59));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(controller.canAccess, isTrue);
    expect(find.text('Черновик'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    session.dispose();
  });

  test(
    'forgot PIN survives restart and resets only the password-authenticated account',
    () async {
      final preferences = MemoryAuthPreferencesStorage();
      final repo = testPinRepository();
      await repo.create('https://backend.test|1', '1234');
      await repo.create('https://backend.test|2', '5678');
      var session = testSession(preferencesStorage: preferences);
      var controller = PinLockController(session: session, repository: repo);
      await session.login('+77012345678', 'password');
      await settleController(controller);
      await controller.forgotPin();
      expect(await repo.read('https://backend.test|1'), isNotNull);
      controller.dispose();
      session.dispose();

      // A restored token alone cannot authorize resetting the saved PIN.
      final storage = MemoryTokenStorage();
      await storage.write('jwt');
      session = testSession(storage: storage, preferencesStorage: preferences);
      controller = PinLockController(session: session, repository: repo);
      await session.restore();
      await settleController(controller);
      expect(controller.status, PinLockStatus.unlock);
      expect(await repo.read('https://backend.test|1'), isNotNull);
      controller.dispose();
      session.dispose();

      session = testSession(preferencesStorage: preferences, id: 2);
      controller = PinLockController(session: session, repository: repo);
      await session.login('+77098765432', 'password');
      await settleController(controller);
      expect(controller.canAccess, isTrue);
      expect(await repo.read('https://backend.test|1'), isNotNull);
      expect(await repo.read('https://backend.test|2'), isNotNull);
      expect(preferences.pinResetAccount, 'https://backend.test|1');
      controller.dispose();
      session.dispose();

      session = testSession(preferencesStorage: preferences);
      controller = PinLockController(session: session, repository: repo);
      await session.login('+77012345678', 'password');
      await settleController(controller);
      expect(controller.status, PinLockStatus.create);
      expect(await repo.read('https://backend.test|1'), isNull);
      expect(await repo.read('https://backend.test|2'), isNotNull);
      expect(preferences.pinResetAccount, isNull);
      controller.dispose();
      session.dispose();
    },
  );

  testWidgets(
    'password login requires PIN creation and matching confirmation',
    (tester) async {
      final session = testSession();
      final repo = testPinRepository();
      final controller = PinLockController(session: session, repository: repo);
      await tester.pumpWidget(app(controller));
      expect(find.byKey(const ValueKey('private-field')), findsOneWidget);
      await session.login('+77012345678', 'password');
      await tester.pumpAndSettle();
      expect(find.text('Создайте ПИН-код'), findsOneWidget);
      expect(find.byKey(const ValueKey('private-field')), findsNothing);
      await enterPin(tester, '0123');
      expect(find.text('Повторите ПИН-код'), findsOneWidget);
      expect(await repo.read('https://backend.test|1'), isNull);
      await enterPin(tester, '0124');
      expect(
        find.text('ПИН-коды не совпадают. Повторите ввод'),
        findsOneWidget,
      );
      expect(controller.canAccess, isFalse);
      expect(find.text('Повторите ПИН-код'), findsOneWidget);
      await enterPin(tester, '0123');
      expect(controller.canAccess, isTrue);
      expect(find.byKey(const ValueKey('private-field')), findsOneWidget);
      expect(await repo.read('https://backend.test|1'), isNotNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      session.dispose();
    },
  );

  testWidgets(
    'restart and background require PIN while preserving the open form',
    (tester) async {
      final session = testSession();
      final repo = testPinRepository();
      var now = DateTime(2026, 10, 13, 12);
      await repo.create('https://backend.test|1', '1234');
      await session.login('+77012345678', 'password');
      await session.restore();
      var controller = PinLockController(session: session, repository: repo);
      await tester.pumpWidget(app(controller, now: () => now));
      await tester.pumpAndSettle();
      expect(find.text('Введите ПИН-код'), findsOneWidget);
      await enterPin(tester, '9999');
      expect(find.text('Неверный ПИН-код'), findsOneWidget);
      expect(find.byKey(const ValueKey('private-field')), findsNothing);
      await enterPin(tester, '1234');
      await tester.enterText(
        find.byKey(const ValueKey('private-field')),
        'Черновик наряда',
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.byKey(const ValueKey('pin-privacy-cover')), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(controller.canAccess, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      now = now.add(const Duration(seconds: 60));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Введите ПИН-код'), findsOneWidget);
      expect(find.text('Черновик наряда'), findsNothing);
      await enterPin(tester, '1234');
      expect(find.text('Черновик наряда'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await session.restore();
      controller = PinLockController(session: session, repository: repo);
      await tester.pumpWidget(app(controller));
      await tester.pumpAndSettle();
      expect(find.text('Введите ПИН-код'), findsOneWidget);
      expect(controller.canAccess, isFalse);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      session.dispose();
    },
  );

  test('forgot PIN keeps it until a successful new password login', () async {
    final session = testSession();
    final repo = testPinRepository();
    await repo.create('https://backend.test|1', '1234');
    await session.login('+77012345678', 'password');
    final controller = PinLockController(session: session, repository: repo);
    await settleController(controller);
    await controller.forgotPin();
    expect(session.authenticated, isFalse);
    expect(await repo.read('https://backend.test|1'), isNotNull);
    await session.login('+77012345678', 'password');
    await settleController(controller);
    expect(controller.status, PinLockStatus.create);
    expect(await repo.read('https://backend.test|1'), isNull);
    expect(await controller.submit('4321'), isTrue);
    expect(
      (await repo.verify('https://backend.test|1', '1234')).status,
      PinVerificationStatus.incorrect,
    );
    controller.dispose();
    session.dispose();
  });

  test(
    'refreshing user profile does not unlock or repeatedly lock a session',
    () async {
      final session = testSession();
      final repo = testPinRepository();
      await session.login('+77012345678', 'password');
      final controller = PinLockController(session: session, repository: repo);
      await settleController(controller);
      await session.refreshUser();
      expect(controller.canAccess, isFalse);
      await controller.submit('1234');
      await session.refreshUser();
      expect(controller.canAccess, isTrue);
      controller.dispose();
      session.dispose();
    },
  );

  test(
    'late verification cannot unlock an app locked again in the background',
    () async {
      final session = testSession();
      final storage = DelayedPinStorage();
      final repo = PinRepository(
        storage: storage,
        keyStorage: MemoryPinKeyStorage(),
      );
      await repo.create('https://backend.test|1', '1234');
      await session.login('+77012345678', 'password');
      final controller = PinLockController(session: session, repository: repo);
      await settleController(controller);
      controller.lock();
      await settleController(controller);
      storage.delay = Completer<void>();
      final result = controller.submit('1234');
      await Future<void>.delayed(Duration.zero);
      controller.lock();
      storage.delay!.complete();
      expect(await result, isFalse);
      await settleController(controller);
      expect(controller.status, PinLockStatus.unlock);
      expect(controller.canAccess, isFalse);
      controller.dispose();
      session.dispose();
    },
  );

  testWidgets(
    'storage failure blocks protected routes and offers retry or password login',
    (tester) async {
      final session = testSession();
      await session.login('+77012345678', 'password');
      final controller = PinLockController(
        session: session,
        repository: PinRepository(
          storage: BrokenPinStorage(),
          keyStorage: MemoryPinKeyStorage(),
        ),
      );
      await tester.pumpWidget(app(controller));
      await tester.pumpAndSettle();
      expect(controller.status, PinLockStatus.storageError);
      expect(find.byKey(const ValueKey('private-field')), findsNothing);
      expect(find.text('Забыли ПИН-код?'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      session.dispose();
    },
  );
}

class DelayedPinStorage extends MemoryPinStorage {
  Completer<void>? delay;
  @override
  Future<PinRecord?> read(String account) async {
    await delay?.future;
    return super.read(account);
  }
}

class BrokenPinStorage extends MemoryPinStorage {
  @override
  Future<PinRecord?> read(String account) async =>
      throw StateError('database unavailable');
}

class DelayedResetPreferences extends MemoryAuthPreferencesStorage {
  final saved = Completer<void>();

  @override
  Future<void> writePinResetAccount(String? account) async {
    await super.writePinResetAccount(account);
    if (account != null) await saved.future;
  }
}
