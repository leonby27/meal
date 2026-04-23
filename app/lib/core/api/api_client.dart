import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';

/// Builds an [http_io.IOClient] backed by Dart's `HttpClient` (BoringSSL,
/// Dart's own DNS resolver). Works on every platform but has a history of
/// `SocketException: Failed host lookup` on iOS when the device has a VPN,
/// iCloud Private Relay, or DNS profiles.
http.Client _createIoClient() => http_io.IOClient();

/// Builds a [CupertinoClient] backed by NSURLSession. iOS/macOS only.
///
/// NOTE: we intentionally do NOT set `waitsForConnectivity = true`. With
/// that flag, `NSURLSession` may wait for a "satisfactory" network path
/// instead of failing fast, which made requests hang on some iOS devices.
http.Client? _createCupertinoClient() {
  if (!(Platform.isIOS || Platform.isMacOS)) return null;
  final config = URLSessionConfiguration.ephemeralSessionConfiguration()
    ..allowsCellularAccess = true
    ..allowsConstrainedNetworkAccess = true
    ..allowsExpensiveNetworkAccess = true
    ..timeoutIntervalForRequest = const Duration(seconds: 20);
  return CupertinoClient.fromSessionConfiguration(config);
}

/// Builds an [http_io.IOClient] that resolves hostnames via DNS-over-HTTPS
/// (DoH) instead of the system resolver, then connects to the resolved IP
/// directly. SNI / Host header / certificate validation still use the
/// original hostname, so TLS and HTTP semantics remain intact.
///
/// This is the escape hatch for environments where the device's system
/// DNS returns NXDOMAIN instantly for our host while Safari works fine —
/// i.e. when the system resolver is tampered with (DNS profile, parental
/// controls, carrier-level filter) but browsers use encrypted DNS.
http.Client _createDohClient() {
  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);
  httpClient.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
    if (proxyHost != null) {
      return Socket.startConnect(proxyHost, proxyPort ?? uri.port);
    }
    final host = uri.host;
    if (_isIpLiteral(host)) {
      return Socket.startConnect(host, uri.port);
    }
    final ip = await _DohResolver.resolve(host);
    return Socket.startConnect(ip ?? host, uri.port);
  };
  return http_io.IOClient(httpClient);
}

bool _isIpLiteral(String host) {
  if (host.contains(':')) return true; // IPv6
  return RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host);
}

/// Minimal DNS-over-HTTPS client. Queries well-known public resolvers by
/// direct IP (so its own operation does not depend on system DNS) and
/// returns the first A-record IPv4 address. Results are cached in-memory
/// for [_dohCacheTtl] to keep per-request overhead negligible.
class _DohResolver {
  _DohResolver._();

  static const Duration _dohCacheTtl = Duration(minutes: 10);
  static final Map<String, _DohCacheEntry> _cache = {};

  /// Providers tried in order. Each is reachable by direct IP (no DNS),
  /// and each serves a certificate valid for that IP.
  static const List<List<String>> _providers = [
    ['Cloudflare', 'https://1.1.1.1/dns-query'],
    ['Google', 'https://8.8.8.8/dns-query'],
    ['Quad9', 'https://9.9.9.9/dns-query'],
  ];

  static Future<String?> resolve(String hostname) async {
    final cached = _cache[hostname];
    if (cached != null && cached.isFresh) {
      return cached.ip;
    }
    for (final provider in _providers) {
      final endpoint = provider[1];
      try {
        final ip = await _query(endpoint, hostname)
            .timeout(const Duration(seconds: 6));
        if (ip != null) {
          _cache[hostname] = _DohCacheEntry(ip, DateTime.now());
          return ip;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> _query(String endpoint, String hostname) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse(
        '$endpoint?name=${Uri.encodeQueryComponent(hostname)}&type=A',
      );
      final req = await client.getUrl(uri);
      req.headers.set('Accept', 'application/dns-json');
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final answers = json['Answer'];
      if (answers is! List) return null;
      for (final a in answers) {
        if (a is Map && a['type'] == 1) {
          final data = a['data'];
          if (data is String && _isIpLiteral(data)) return data;
        }
      }
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

class _DohCacheEntry {
  _DohCacheEntry(this.ip, this.at);
  final String ip;
  final DateTime at;
  bool get isFresh =>
      DateTime.now().difference(at) < _DohResolver._dohCacheTtl;
}

class ApiClient {
  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String defaultBaseUrl = 'https://leonby27-meal-29f6.twc1.net';

  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  // Three independent clients. The photo upload path picks whichever one
  // actually works on this device and pins [_client] to it for the rest
  // of the session.
  //   • _ioClient       — Dart HttpClient + system resolver (default on Android).
  //   • _dohClient      — Dart HttpClient + DNS-over-HTTPS (1.1.1.1/8.8.8.8/9.9.9.9).
  //                       Bypasses a broken/censored system resolver.
  //   • _cupertinoClient— NSURLSession via cupertino_http (iOS/macOS only).
  final http.Client _ioClient = _createIoClient();
  final http.Client _dohClient = _createDohClient();
  final http.Client? _cupertinoClient = _createCupertinoClient();
  late http.Client _client =
      _cupertinoClient ?? _ioClient; // active client — swapped by probe
  bool _uploadClientSelected = false;

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
    _uploadClientSelected = false;
    _client = _cupertinoClient ?? _ioClient;
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
    await _selectUploadClient();
    await ensureAuthenticated();

    Future<http.Response> manualUpload() async {
      final boundary =
          '----MealTrackerBoundary${DateTime.now().microsecondsSinceEpoch}';
      final headerBuf = BytesBuilder(copy: false);

      void writeField(String name, String value) {
        headerBuf.add(utf8.encode('--$boundary\r\n'));
        headerBuf.add(
          utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'),
        );
        headerBuf.add(utf8.encode('$value\r\n'));
      }

      if (locale != null) writeField('locale', locale);
      if (text != null && text.isNotEmpty) writeField('text', text);

      headerBuf.add(utf8.encode('--$boundary\r\n'));
      headerBuf.add(utf8.encode(
        'Content-Disposition: form-data; name="file"; filename="photo.jpg"\r\n',
      ));
      headerBuf.add(utf8.encode('Content-Type: image/jpeg\r\n\r\n'));

      final footer = utf8.encode('\r\n--$boundary--\r\n');
      final body = BytesBuilder(copy: false)
        ..add(headerBuf.takeBytes())
        ..add(imageBytes)
        ..add(footer);

      final headers = <String, String>{
        'Content-Type': 'multipart/form-data; boundary=$boundary',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

      return _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: body.takeBytes(),
          )
          .timeout(_uploadTimeout);
    }

    var response = await _withRetry(manualUpload);
    if (response.statusCode == 401) {
      await ensureAuthenticated(forceRefresh: true);
      response = await _withRetry(manualUpload);
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

  Future<void> _selectUploadClient() async {
    if (_uploadClientSelected) return;
    if (!(Platform.isIOS || Platform.isMacOS)) {
      _client = _ioClient;
      _uploadClientSelected = true;
      return;
    }

    if (await _probeHealth(_ioClient)) {
      _client = _ioClient;
      _uploadClientSelected = true;
      return;
    }

    if (await _probeHealth(_dohClient)) {
      _client = _dohClient;
      _uploadClientSelected = true;
      return;
    }

    final cupertinoClient = _cupertinoClient;
    if (cupertinoClient != null && await _probeHealth(cupertinoClient)) {
      _client = cupertinoClient;
      _uploadClientSelected = true;
      return;
    }

    throw NetworkException(currentL10n.networkRetryFailed);
  }

  Future<bool> _probeHealth(http.Client client) async {
    try {
      final resp = await client.get(Uri.parse('$_baseUrl/health')).timeout(
            const Duration(seconds: 10),
          );
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Transient HTTP statuses that we retry automatically. 502/503/504 are
  /// classic "upstream hiccup" codes (our server surfaces Gemini outages as
  /// 502/503). 429 is rate-limit — a small backoff is enough most of the time.
  /// 500 is conservatively included because our backend sometimes returns it
  /// on transient Gemini failures.
  static const Set<int> _retriableStatuses = {429, 500, 502, 503, 504};

  Future<http.Response> _withRetry(Future<http.Response> Function() request) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await request();
        if (_retriableStatuses.contains(response.statusCode) &&
            attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
        return response;
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
