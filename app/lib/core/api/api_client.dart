import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String defaultBaseUrl = 'https://leonby27-meal-29f6.twc1.net';

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
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (params != null) {
      uri = uri.replace(queryParameters: params);
    }
    final response = await _client.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadImage(String path, Uint8List imageBytes) async {
    Future<http.Response> doRequest() async {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
      request.headers.addAll({
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    }

    var response = await doRequest();
    if (response.statusCode == 401) {
      await ensureAuthenticated(forceRefresh: true);
      response = await doRequest();
    }
    return _handleResponse(response);
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
    throw ApiException(
      statusCode: response.statusCode,
      message: body is Map ? (body['detail']?.toString() ?? 'Unknown error') : response.body,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
