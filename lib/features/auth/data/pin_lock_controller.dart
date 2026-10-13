import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_session.dart';
import 'pin_repository.dart';

enum PinLockStatus {
  signedOut,
  loading,
  create,
  unlock,
  unlocked,
  storageError,
}

class PinLockController extends ChangeNotifier {
  PinLockController({
    required this.session,
    required this.repository,
    this.enabled = true,
  }) {
    if (enabled) {
      session.addListener(_sessionChanged);
      _sessionChanged();
    }
  }

  final AuthSession session;
  final PinRepository repository;
  final bool enabled;
  PinLockStatus status = PinLockStatus.signedOut;
  bool busy = false;
  bool incorrect = false;
  DateTime? lockedUntil;
  String? _account;
  String? _token;
  int _passwordLoginRevision = 0;
  bool _authenticatedWithPassword = false;
  bool _allowPasswordUnlock = false;
  bool _passwordResetAllowed = false;
  int _generation = 0;
  bool _disposed = false;

  bool get canAccess => !enabled || status == PinLockStatus.unlocked;
  bool get blocking => enabled && session.authenticated && !canAccess;

  void _sessionChanged() {
    final user = session.user;
    final account = session.authenticated && user != null
        ? '${session.baseUrl}|${user.id}'
        : null;
    if (account == _account &&
        session.accessToken == _token &&
        session.passwordLoginRevision == _passwordLoginRevision &&
        session.authenticatedWithPassword == _authenticatedWithPassword) {
      return;
    }
    _account = account;
    _token = session.accessToken;
    _passwordLoginRevision = session.passwordLoginRevision;
    _authenticatedWithPassword = session.authenticatedWithPassword;
    if (account == null) {
      _allowPasswordUnlock = false;
      _passwordResetAllowed = false;
      _generation++;
      status = PinLockStatus.signedOut;
      busy = false;
      incorrect = false;
      lockedUntil = null;
      notifyListeners();
    } else {
      _allowPasswordUnlock = session.authenticatedWithPassword;
      _passwordResetAllowed = session.authenticatedWithPassword;
      unawaited(_prepare());
    }
  }

  Future<void> _prepare() async {
    final account = _account;
    if (!enabled || account == null || _disposed) return;
    final generation = ++_generation;
    status = PinLockStatus.loading;
    busy = false;
    incorrect = false;
    lockedUntil = null;
    notifyListeners();
    try {
      // A reset is permitted only after a successful password login.
      if (_passwordResetAllowed) {
        final resetAccount = await session.preferencesStorage
            .readPinResetAccount();
        if (!_current(generation)) return;
        if (resetAccount == account) {
          await repository.delete(account);
          if (!_current(generation)) return;
          await session.preferencesStorage.writePinResetAccount(null);
          if (!_current(generation)) return;
        }
        _passwordResetAllowed = false;
      }
      final record = await repository.read(account);
      if (!_current(generation)) return;
      status = record == null
          ? PinLockStatus.create
          : _allowPasswordUnlock
          ? PinLockStatus.unlocked
          : PinLockStatus.unlock;
      lockedUntil = status == PinLockStatus.unlock ? record?.lockedUntil : null;
    } catch (_) {
      if (!_current(generation)) return;
      status = PinLockStatus.storageError;
    }
    notifyListeners();
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  void lock() {
    if (enabled && session.authenticated) {
      _allowPasswordUnlock = false;
      unawaited(_prepare());
    }
  }

  Future<void> retry() => _prepare();

  Future<bool> submit(String pin) async {
    if (busy || !PinRepository.isValid(pin)) return false;
    final account = _account;
    if (account == null ||
        !{PinLockStatus.create, PinLockStatus.unlock}.contains(status)) {
      return false;
    }
    final generation = _generation;
    final creating = status == PinLockStatus.create;
    busy = true;
    incorrect = false;
    notifyListeners();
    var success = false;
    try {
      if (creating) {
        await repository.create(account, pin);
        success = true;
      } else {
        final result = await repository.verify(account, pin);
        if (!_current(generation)) return false;
        lockedUntil = result.lockedUntil;
        success = result.status == PinVerificationStatus.matched;
        incorrect = !success;
      }
      if (!_current(generation)) return false;
      status = success ? PinLockStatus.unlocked : PinLockStatus.unlock;
    } catch (_) {
      if (!_current(generation)) return false;
      status = PinLockStatus.storageError;
    }
    if (_current(generation)) {
      busy = false;
      notifyListeners();
    }
    return success && _current(generation);
  }

  Future<void> forgotPin() => _leaveAccount(reset: true);

  Future<void> useAnotherAccount() => _leaveAccount(reset: false);

  Future<void> _leaveAccount({required bool reset}) async {
    if (busy || _account == null) return;
    final account = _account!;
    final token = session.accessToken;
    final loginRevision = session.passwordLoginRevision;
    _generation++;
    _allowPasswordUnlock = false;
    _passwordResetAllowed = false;
    busy = true;
    notifyListeners();
    if (reset) {
      try {
        await session.preferencesStorage.writePinResetAccount(account);
      } catch (_) {
        if (!_disposed && _account == account) {
          busy = false;
          status = PinLockStatus.storageError;
          notifyListeners();
        }
        return;
      }
    }
    if (_disposed ||
        _account != account ||
        session.accessToken != token ||
        session.passwordLoginRevision != loginRevision) {
      return;
    }
    try {
      await session.logout();
    } catch (_) {
      // Logout expires the local session even if the device is offline.
      if (session.authenticated) await session.expire();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    if (enabled) session.removeListener(_sessionChanged);
    super.dispose();
  }
}
