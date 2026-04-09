import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meal_tracker/core/api/api_client.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhotoKey = 'user_photo_url';
  static const String _isLoggedInKey = 'is_logged_in';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '1077821577314-ftou96r9s805ipc8i8jcjn4i8t706a1a.apps.googleusercontent.com',
  );

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhotoUrl => _userPhotoUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _userName = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
    _userPhotoUrl = prefs.getString(_userPhotoKey);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;

      final api = ApiClient();
      try {
        final backendResult = await api.post('/api/auth/google', {
          'id_token': idToken ?? '',
          'name': account.displayName,
          'email': account.email,
          'photo_url': account.photoUrl,
        });
        await api.setToken(backendResult['access_token'] as String);
      } catch (_) {
        // Backend may not be available yet — save locally, sync later
      }

      _userName = account.displayName;
      _userEmail = account.email;
      _userPhotoUrl = account.photoUrl;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      if (_userName != null) await prefs.setString(_userNameKey, _userName!);
      if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
      if (_userPhotoUrl != null) {
        await prefs.setString(_userPhotoKey, _userPhotoUrl!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await ApiClient().clearToken();

    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _userPhotoUrl = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhotoKey);

    notifyListeners();
  }

  Future<void> skipLogin() async {
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);

    final api = ApiClient();
    try {
      await api.ensureAuthenticated();
    } catch (_) {}

    notifyListeners();
  }
}
