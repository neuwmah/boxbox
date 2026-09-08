import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'player_state.dart';

/// Base of the API. Override in build with:
/// `--dart-define=API_BASE_URL=https://boxbox-444.fly.dev`
class ApiConfig {
  static const fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (fromEnv.isNotEmpty) return _trimSlash(fromEnv);
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String _trimSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

class ApiResult {
  const ApiResult({this.state, this.statusCode, this.conflict});

  final PlayerState? state;
  final int? statusCode;
  final PlayerState? conflict;

  bool get ok =>
      state != null && statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get notFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get unauthorized => statusCode == 401 || statusCode == 403;
  bool get networkError => statusCode == null;
}

/// HTTP client with 10s timeout, Bearer token and retry (1s, 2s, 4s).
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static const _timeout = Duration(seconds: 10);
  static const _backoffs = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  final http.Client _http;
  final String _baseUrl;

  Uri _url(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.idToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResult> getMe() {
    return _request((headers) => _http.get(_url('/me'), headers: headers));
  }

  Future<ApiResult> putMe(PlayerState state) {
    return _request(
      (headers) => _http.put(
        _url('/me'),
        headers: headers,
        body: jsonEncode(state.toJson()),
      ),
    );
  }

  Future<ApiResult> createPlayer(PlayerState state) {
    return _request(
      (headers) => _http.post(
        _url('/players'),
        headers: headers,
        body: jsonEncode(state.toJson()),
      ),
    );
  }

  Future<ApiResult> _request(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final headers = await _headers();
        final response = await send(headers).timeout(_timeout);
        final result = _decode(response);
        if (result.unauthorized) {
          if (attempt == 0) {
            await AuthService.instance.idToken(forceRefresh: true);
            continue;
          }
          AuthService.instance.markUnauthorized();
          return result;
        }
        if (!_shouldRetry(result.statusCode) || attempt == 2) return result;
        debugPrint('API HTTP ${result.statusCode} retry ${attempt + 1}/3');
      } catch (error, stack) {
        lastError = error;
        debugPrint('API attempt ${attempt + 1}/3 failed: $error');
        debugPrint('$stack');
        if (attempt == 2) return const ApiResult();
      }
      await Future<void>.delayed(_backoffs[attempt]);
    }
    debugPrint('API gave up after retries: $lastError');
    return const ApiResult();
  }

  ApiResult _decode(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic>? json;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) json = decoded;
      } catch (error) {
        debugPrint('API invalid JSON ($status): $error');
      }
    }

    if (status == 409) {
      final server = json?['server'];
      return ApiResult(
        statusCode: status,
        conflict: server is Map<String, dynamic>
            ? PlayerState.fromJson(server)
            : PlayerState.fromJson(json),
      );
    }

    if (status >= 200 && status < 300) {
      return ApiResult(
        statusCode: status,
        state: PlayerState.fromJson(json),
      );
    }

    return ApiResult(statusCode: status, state: PlayerState.fromJson(json));
  }

  bool _shouldRetry(int? status) => status == null || status >= 500;
}
