import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

// MARK: - API exception

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  final int statusCode;
  final String message;
  final dynamic data;

  @override
  String toString() {
    return 'ApiException('
        'statusCode: $statusCode, '
        'message: $message'
        ')';
  }
}

// MARK: - API response

class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
  });

  final T data;
  final int statusCode;
  final Map<String, String> headers;

  int? get totalCount {
    final value = headers['x-total-count'];

    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }
}

// MARK: - API client

class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUrl = _normalizeBaseUrl(baseUrl),
      _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;
  void Function(String token)? onUnauthorized;

  String? _accessToken;

  // MARK: Token

  String? get accessToken => _accessToken;

  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  void setAccessToken(String? token) {
    final normalized = token?.trim();

    if (normalized == null || normalized.isEmpty) {
      _accessToken = null;
      return;
    }

    _accessToken = normalized;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  // MARK: GET

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final requestToken = authenticated ? _accessToken : null;
    final response = await _httpClient
        .get(
          _buildUri(path, queryParameters: queryParameters),
          headers: _buildHeaders(
            headers: headers,
            authenticated: authenticated,
          ),
        )
        .timeout(timeout);
    return _handleResponse(response, requestToken: requestToken);
  }

  // MARK: POST

  Future<ApiResponse<dynamic>> sendMultipart(
    http.MultipartRequest request, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final requestToken = _accessToken;
    request.headers.addAll(
      _buildHeaders(authenticated: true)..remove('Content-Type'),
    );
    final response = await _httpClient
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
    return _handleResponse(response, requestToken: requestToken);
  }

  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final requestToken = _accessToken;
    final response = await _httpClient
        .get(
          _buildUri(path, queryParameters: queryParameters),
          headers: _buildHeaders(authenticated: true),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleResponse(response, requestToken: requestToken);
    }
    return response.bodyBytes;
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    final requestToken = authenticated ? _accessToken : null;

    final response = await _httpClient
        .post(
          uri,
          headers: _buildHeaders(
            headers: headers,
            authenticated: authenticated,
          ),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response, requestToken: requestToken);
  }

  // MARK: PATCH

  Future<ApiResponse<dynamic>> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final requestToken = authenticated ? _accessToken : null;

    final response = await _httpClient
        .patch(
          _buildUri(path, queryParameters: queryParameters),
          headers: _buildHeaders(
            headers: headers,
            authenticated: authenticated,
          ),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
    return _handleResponse(response, requestToken: requestToken);
  }

  // MARK: DELETE

  Future<ApiResponse<dynamic>> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final requestToken = authenticated ? _accessToken : null;

    final response = await _httpClient
        .delete(
          _buildUri(path, queryParameters: queryParameters),
          headers: _buildHeaders(
            headers: headers,
            authenticated: authenticated,
          ),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response, requestToken: requestToken);
  }

  // MARK: URI

  Uri _buildUri(String path, {Map<String, dynamic>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse('$_baseUrl$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final params = <String, String>{};

    for (final entry in queryParameters.entries) {
      final value = entry.value;

      if (value == null) {
        continue;
      }

      if (value is Iterable) {
        params[entry.key] = value.map((item) => item.toString()).join(',');
        continue;
      }

      params[entry.key] = value.toString();
    }

    return uri.replace(queryParameters: params);
  }

  // MARK: Headers

  Map<String, String> _buildHeaders({
    Map<String, String>? headers,
    required bool authenticated,
  }) {
    final result = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = _accessToken;

      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Access token отсутствует',
        );
      }

      result['Authorization'] = 'Bearer $token';
    }

    if (headers != null) {
      result.addAll(headers);
    }

    return result;
  }

  // MARK: Response

  ApiResponse<dynamic> _handleResponse(
    http.Response response, {
    String? requestToken,
  }) {
    if (response.statusCode == 401 &&
        requestToken != null &&
        requestToken == _accessToken) {
      onUnauthorized?.call(requestToken);
    }
    final decoded = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse<dynamic>(
        data: decoded,
        statusCode: response.statusCode,
        headers: response.headers,
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(decoded, response.statusCode),
      data: decoded,
    );
  }

  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final text = utf8.decode(response.bodyBytes);

    if (text.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  String _extractErrorMessage(dynamic data, int statusCode) {
    if (data is Map) {
      final message = data['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final error = data['error'];

      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      final details = data['details'];

      if (details is String && details.trim().isNotEmpty) {
        return details;
      }
    }

    return switch (statusCode) {
      400 => 'Ошибка в данных запроса',
      401 => 'Необходимо войти в систему',
      403 => 'Недостаточно прав',
      404 => 'Данные не найдены',
      409 => 'Конфликт данных',
      422 => 'Не удалось обработать данные',
      500 => 'Ошибка сервера',
      502 => 'Сервис временно недоступен',
      _ => 'Ошибка запроса ($statusCode)',
    };
  }

  // MARK: Dispose

  void dispose() {
    _httpClient.close();
  }

  // MARK: Helpers

  static String _normalizeBaseUrl(String value) {
    var result = value.trim();

    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }
}
