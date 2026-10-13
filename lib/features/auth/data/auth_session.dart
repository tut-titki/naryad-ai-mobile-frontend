import 'package:http_parser/http_parser.dart';
import 'package:mineral/core/services/photo_upload_rules.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract interface class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  final _storage = const FlutterSecureStorage();
  static const _key = 'mineral.auth.token';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> delete() => _storage.delete(key: _key);
}

// Web tokens stay in memory instead of localStorage.
class MemoryTokenStorage implements TokenStorage {
  String? _token;
  @override
  Future<String?> read() async => _token;
  @override
  Future<void> write(String token) async {
    _token = token;
  }

  @override
  Future<void> delete() async {
    _token = null;
  }
}

class AuthUser {
  AuthUser.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      fullName = json['fullName'] as String,
      role = json['role'] as String,
      phone = json['phone'] as String?,
      language = json['language'] as String? ?? 'ru',
      specialty = json['specialty'] as String? ?? '',
      grade = json['grade'] as int?,
      brigadeId = json['brigadeId'] as int?,
      isOnShift = json['isOnShift'] as bool? ?? false;
  final int id;
  final String fullName;
  final String role;
  final String? phone;
  final String language;
  final String specialty;
  final int? grade;
  final int? brigadeId;
  final bool isOnShift;
  String? get mobileRoute => switch (role) {
    'EXECUTOR' => '/executor',
    'MASTER' => '/master',
    _ => null,
  };
}

class ApiException implements Exception {
  const ApiException(
    this.status,
    this.message, {
    this.retryAfter,
    this.details,
  });
  final int status;
  final String message;
  final Duration? retryAfter;
  final Object? details;

  String? fieldMessage(String field) {
    Object? decoded = details;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        /* Plain-text details are also supported. */
      }
    }
    if (decoded is List) {
      for (final issue in decoded) {
        if (issue is! Map) continue;
        final path = issue['path'];
        final matches = path == field || (path is List && path.contains(field));
        if (matches && issue['message'] is String) {
          return issue['message'] as String;
        }
      }
    }
    if (decoded is Map) {
      final direct = decoded[field];
      if (direct is String) return direct;
      if (direct is List && direct.isNotEmpty) return direct.first.toString();
      final path = decoded['path'];
      if ((path == field || (path is List && path.contains(field))) &&
          decoded['message'] is String) {
        return decoded['message'] as String;
      }
    }
    if (decoded is String) {
      final text = decoded.toLowerCase();
      if (field == 'phone' && text.contains('телефон')) return decoded;
      if (field == 'newPassword' && text.contains('парол')) return decoded;
    }
    return null;
  }
}

class AuthSession extends ChangeNotifier {
  AuthSession({
    http.Client? client,
    TokenStorage? storage,
    this.baseUrl = 'https://hackaton.fenixkst.kz',
  }) : _client = client ?? http.Client(),
       _storage =
           storage ?? (kIsWeb ? MemoryTokenStorage() : SecureTokenStorage());
  final http.Client _client;
  final TokenStorage _storage;
  final String baseUrl;
  String? _token;
  AuthUser? user;
  String? pushToken;
  DateTime? blockedUntil;
  int _generation = 0;
  Future<void> _storagePending = Future.value();

  Future<T> _store<T>(Future<T> Function() operation) {
    final result = _storagePending.then((_) => operation());
    _storagePending = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  void _checkGeneration(int generation) {
    if (generation != _generation) throw const ApiException(401, '');
  }

  String? get accessToken => _token;
  bool get authenticated => _token != null && user != null;
  String? get token => _token;

  Future<Object?> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool protected = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final requestToken = protected ? _token : null;
    final generation = _generation;
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Content-Type'] = 'application/json';
    if (protected && _token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(timeout),
    ).timeout(timeout);
    if (response.statusCode == 401 &&
        requestToken != null &&
        requestToken == _token &&
        generation == _generation) {
      await expire();
    }

    Object? decoded;
    try {
      if (response.bodyBytes.isNotEmpty) {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } on FormatException {
      // прокси может вернуть ошибку не в json
    }
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    throw ApiException(
      response.statusCode,
      data['error'] as String? ?? '',
      details: data['details'],
      retryAfter: seconds == null ? null : Duration(seconds: seconds),
    );
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool protected = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final result = await _requestJson(
      method,
      path,
      body: body,
      protected: protected,
      timeout: timeout,
    );
    if (result == null) return {};
    if (result is! Map) {
      throw const FormatException("Ожидался JSON-обьект");
    }
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> requestList(String path) async {
    final result = await _requestJson("GET", path);
    if (result is! List) {
      throw const FormatException("Ожидался JSON-массив");
    }
    return result.map((item) {
      if (item is! Map) {
        throw const FormatException("Некорректный элемент списка");
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Future<Map<String, dynamic>> uploadPhoto(String name, Uint8List bytes) async {
    validatePhotoSize(bytes.length);
    final requestToken = _token;
    final generation = _generation;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/uploads'),
    );
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: name,
        contentType: MediaType('image', switch (name
            .split('.')
            .last
            .toLowerCase()) {
          'png' => 'png',
          'webp' => 'webp',
          'gif' => 'gif',
          'heic' => 'heic',
          'heif' => 'heif',
          _ => 'jpeg',
        }),
      ),
    );
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 60)),
    ).timeout(const Duration(seconds: 60));
    if (response.statusCode == 401 &&
        requestToken != null &&
        requestToken == _token &&
        generation == _generation) {
      await expire();
    }
    Object? result;
    try {
      if (response.bodyBytes.isNotEmpty) {
        result = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } on FormatException {
      /* Proxy errors can have a non-JSON body. */
    }
    final decoded = result is Map
        ? Map<String, dynamic>.from(result)
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        decoded['error'] as String? ?? '',
        details: decoded['details'],
      );
    }
    if (decoded['url'] is! String || (decoded['url'] as String).isEmpty) {
      throw const FormatException('Ответ загрузки не содержит URL фото');
    }
    return decoded;
  }

  Future<Uint8List> downloadPhoto(String url) async {
    final uri = Uri.parse(baseUrl).resolve(url);
    final base = Uri.parse(baseUrl);
    final headers = <String, String>{};
    if (!uri.queryParameters.containsKey('sig') &&
        uri.origin == base.origin &&
        _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));
    // Signed image URLs are independent of the application session.
    if (response.statusCode != 200) throw ApiException(response.statusCode, '');
    return response.bodyBytes;
  }

  Future<AuthUser> login(String phone, String password) async {
    final until = blockedUntil;
    if (until != null && until.isAfter(DateTime.now())) {
      throw ApiException(429, '', retryAfter: until.difference(DateTime.now()));
    }
    if (password.isEmpty) throw const ApiException(400, '');
    final generation = ++_generation;
    Map<String, dynamic> result;
    try {
      result = await request(
        'POST',
        '/api/auth/login',
        protected: false,
        body: {'phone': phone.trim(), 'password': password},
      );
    } on ApiException catch (error) {
      if (generation == _generation &&
          error.status == 429 &&
          error.retryAfter != null) {
        blockedUntil = DateTime.now().add(error.retryAfter!);
      }
      rethrow;
    }
    _checkGeneration(generation);
    final token = result['token'] as String;
    final loginUser = AuthUser.fromJson(
      Map<String, dynamic>.from(result['user'] as Map),
    );
    if (loginUser.mobileRoute == null) throw const ApiException(403, '');
    _token = token;
    try {
      final profile = await request('GET', '/api/auth/me');
      _checkGeneration(generation);
      final fullUser = AuthUser.fromJson(profile);
      if (fullUser.mobileRoute == null) throw const ApiException(403, '');
      await _store(() => _storage.write(token));
      _checkGeneration(generation);
      user = fullUser;
      blockedUntil = null;
      notifyListeners();
      return fullUser;
    } catch (_) {
      if (generation == _generation) {
        _token = null;
        user = null;
      }
      rethrow;
    }
  }

  Future<AuthUser?> restore() async {
    final generation = ++_generation;
    final token = await _store(_storage.read);
    if (generation != _generation) return null;
    _token = token;
    if (_token == null) return null;
    try {
      final profile = AuthUser.fromJson(await request('GET', '/api/auth/me'));
      if (generation != _generation) return null;
      user = profile;
      if (user!.mobileRoute == null) {
        await expire();
        return null;
      }
      notifyListeners();
      return user;
    } on ApiException catch (error) {
      if (error.status == 401) return null;
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    final token = _token;
    final generation = _generation;
    if (token == null) return;
    final profile = AuthUser.fromJson(await request('GET', '/api/auth/me'));
    if (_token != token || generation != _generation) return;
    if (profile.mobileRoute == null) {
      await expire();
      return;
    }
    user = profile;
    notifyListeners();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await request(
      'POST',
      '/api/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> _pushRegistration = Future.value();
  bool _loggingOut = false;

  Future<void> registerPushDevice(String token, String platform) {
    final owner = user?.id;
    final result = _pushRegistration.then((_) async {
      if (_loggingOut || !authenticated || user?.id != owner) {
        throw StateError('Сессия завершена');
      }
      await _registerPushDevice(token, platform);
    });
    _pushRegistration = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _registerPushDevice(String token, String platform) async {
    if (!authenticated) throw StateError('Требуется вход');
    if (token.length < 20 || !{'android', 'ios', 'web'}.contains(platform)) {
      throw ArgumentError('Некорректный токен или платформа устройства');
    }
    final previous = pushToken;
    if (previous != null && previous != token) {
      await request('DELETE', '/api/devices/${Uri.encodeComponent(previous)}');
    }
    // Keep the token even if POST fails: logout must attempt to detach it.
    pushToken = token;
    await request(
      'POST',
      '/api/devices',
      body: {'token': token, 'platform': platform},
    );
  }

  Future<void> logout() async {
    _generation++;
    _loggingOut = true;
    try {
      await _pushRegistration;
      if (pushToken != null && _token != null) {
        await request(
          'DELETE',
          '/api/devices/${Uri.encodeComponent(pushToken!)}',
        );
      }
    } finally {
      try {
        await expire();
      } finally {
        _loggingOut = false;
      }
    }
  }

  Future<void> expire() async {
    _generation++;
    _token = null;
    user = null;
    pushToken = null;
    try {
      await _store(_storage.delete);
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _generation++;
    _client.close();
    super.dispose();
  }
}
