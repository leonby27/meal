import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';

class ApiClient {
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String defaultBaseUrl = 'https://leonby27-meal-29f6.twc1.net';

  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  final http.Client _client = http.Client();
  String _baseUrl = defaultBaseUrl;
  String? _token;

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;
  ApiClient._();

  String get baseUrl => _baseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.contains('192.168.')) {
      await prefs.remove(_baseUrlKey);
      await prefs.remove(_tokenKey);
      _baseUrl = defaultBaseUrl;
      _token = null;
    } else {
      _baseUrl = savedUrl ?? defaultBaseUrl;
      _token = prefs.getString(_tokenKey);
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  Future<void> ensureAuthenticated({bool forceRefresh = false}) async {
    if (_token != null && !forceRefresh) return;
    if (forceRefresh) await clearToken();
    try {
      final result = await post('/api/auth/register', {
        'email': 'local@device.app',
        'password': 'device-auto-pass',
        'name': 'User',
      });
      await setToken(result['access_token'] as String);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        final result = await post('/api/auth/login', {
          'email': 'local@device.app',
          'password': 'device-auto-pass',
        });
        await setToken(result['access_token'] as String);
      } else {
        rethrow;
      }
    }
  }

  bool get isAuthenticated => _token != null;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await _withRetry(() =>
      _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(_requestTimeout),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }
    final response = await _withRetry(() =>
      _client.get(uri, headers: _headers).timeout(_requestTimeout),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadImage(String path, Uint8List imageBytes, {String? locale, String? text}) async {
    Future<http.Response> doRequest() async {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
      request.headers.addAll({
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      if (locale != null) {
        request.fields['locale'] = locale;
      }
      if (text != null && text.isNotEmpty) {
        request.fields['text'] = text;
      }
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamedResponse = await request.send().timeout(_uploadTimeout);
      return http.Response.fromStream(streamedResponse);
    }

    var response = await _withRetry(doRequest);
    if (response.statusCode == 401) {
      await ensureAuthenticated(forceRefresh: true);
      response = await _withRetry(doRequest);
    }
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> recognizeText(String text, {String? locale}) async {
    await ensureAuthenticated();
    final bodyMap = <String, dynamic>{'text': text};
    if (locale != null) bodyMap['locale'] = locale;
    var response = await _withRetry(() =>
      _client.post(
        Uri.parse('$_baseUrl/api/recognize-text'),
        headers: _headers,
        body: jsonEncode(bodyMap),
      ).timeout(_uploadTimeout),
    );
    if (response.statusCode == 401) {
      await ensureAuthenticated(forceRefresh: true);
      response = await _withRetry(() =>
        _client.post(
          Uri.parse('$_baseUrl/api/recognize-text'),
          headers: _headers,
          body: jsonEncode(bodyMap),
        ).timeout(_uploadTimeout),
      );
    }
    return _handleResponse(response);
  }

  Future<http.Response> _withRetry(Future<http.Response> Function() request) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await request();
      } on SocketException catch (e) {
        if (attempt == _maxRetries - 1) throw NetworkException(_friendlyNetworkError(e));
        await _backoff(attempt);
      } on TimeoutException {
        if (attempt == _maxRetries - 1) {
          throw NetworkException(currentL10n.networkTimeout);
        }
        await _backoff(attempt);
      } on HandshakeException {
        if (attempt == _maxRetries - 1) {
          throw NetworkException(currentL10n.networkSslError);
        }
        await _backoff(attempt);
      } on http.ClientException catch (e) {
        if (attempt == _maxRetries - 1) throw NetworkException(currentL10n.networkConnectionError(e.message));
        await _backoff(attempt);
      }
    }
    throw NetworkException(currentL10n.networkRetryFailed);
  }

  Future<void> _backoff(int attempt) =>
      Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));

  String _friendlyNetworkError(SocketException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('host lookup') || msg.contains('no address associated')) {
      return currentL10n.networkHostLookup;
    }
    if (msg.contains('connection refused')) {
      return currentL10n.networkConnectionRefused;
    }
    if (msg.contains('connection reset') || msg.contains('broken pipe')) {
      return currentL10n.networkConnectionReset;
    }
    return currentL10n.networkGenericError;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'raw': response.body};
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body.isNotEmpty ? response.body : 'Server error',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    String? kind;
    String message = 'Unknown error';
    if (body is Map) {
      final detail = body['detail'];
      if (detail is Map) {
        kind = detail['kind']?.toString();
        message = detail['message']?.toString() ?? message;
      } else if (detail != null) {
        message = detail.toString();
      }
    } else {
      message = response.body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      kind: kind,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? kind;

  ApiException({required this.statusCode, required this.message, this.kind});

  @override
  String toString() => 'ApiException($statusCode${kind != null ? '/$kind' : ''}): $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => message;
}
