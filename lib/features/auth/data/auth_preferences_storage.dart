import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthPreferencesStorage {
  Future<String?> readPhone();
  Future<void> writePhone(String phone);
  Future<String?> readPinResetAccount();
  Future<void> writePinResetAccount(String? account);
}

class SecureAuthPreferencesStorage implements AuthPreferencesStorage {
  const SecureAuthPreferencesStorage({required this.scope});
  final String scope;
  static const _storage = FlutterSecureStorage();

  String _key(String name) => 'mineral.auth.$name.$scope';

  @override
  Future<String?> readPhone() => _storage.read(key: _key('last-phone'));

  @override
  Future<void> writePhone(String phone) =>
      _storage.write(key: _key('last-phone'), value: phone);

  @override
  Future<String?> readPinResetAccount() =>
      _storage.read(key: _key('pin-reset-account'));

  @override
  Future<void> writePinResetAccount(String? account) => account == null
      ? _storage.delete(key: _key('pin-reset-account'))
      : _storage.write(key: _key('pin-reset-account'), value: account);
}

class MemoryAuthPreferencesStorage implements AuthPreferencesStorage {
  String? phone;
  String? pinResetAccount;

  @override
  Future<String?> readPhone() async => phone;

  @override
  Future<void> writePhone(String phone) async => this.phone = phone;

  @override
  Future<String?> readPinResetAccount() async => pinResetAccount;

  @override
  Future<void> writePinResetAccount(String? account) async =>
      pinResetAccount = account;
}
