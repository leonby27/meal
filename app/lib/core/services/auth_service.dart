import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/build_info.dart';
import 'package:meal_tracker/core/database/app_database.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhotoKey = 'user_photo_url';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _isPremiumKey = 'is_premium';
  static const String _planNameKey = 'plan_name';
  static const String _nextBillingDateKey = 'next_billing_date';
  static const String _freeEntriesUsedKey = 'free_entries_used';
  static const String _lastSeenBuildKey = 'last_seen_build';
  static const String _authProviderKey = 'auth_provider';
  static const int freeEntryLimit = 10;

  /// Values stored in [_authProviderKey].
  static const String providerGoogle = 'google';
  static const String providerApple = 'apple';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '1077821577314-ftou96r9s805ipc8i8jcjn4i8t706a1a.apps.googleusercontent.com',
  );

  bool _isLoggedIn = false;
  bool _onboardingCompleted = false;

  bool _isPremium = false;
  int _freeEntriesUsed = 0;
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;
  String? _planName;
  String? _nextBillingDate;
  String? _authProvider;

  bool get isLoggedIn => _isLoggedIn;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isPremium => _isPremium;
  int get freeEntriesUsed => _freeEntriesUsed;
  int get freeEntriesRemaining =>
      (freeEntryLimit - _freeEntriesUsed).clamp(0, freeEntryLimit);
  bool get freeTrialExhausted => _freeEntriesUsed >= freeEntryLimit;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhotoUrl => _userPhotoUrl;
  String? get planName => _planName;
  String? get nextBillingDate => _nextBillingDate;
  String? get authProvider => _authProvider;

  /// True when the user completed Google/Apple sign-in (as opposed to
  /// a guest "skip login" session). Apple only returns email/name on the
  /// very first authorization, so UI must NOT rely on [userEmail] alone
  /// to detect a signed-in social account.
  bool get hasSocialAccount => _authProvider != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final lastBuild = prefs.getInt(_lastSeenBuildKey) ?? 0;
    if (lastBuild < 21) {
      await prefs.setBool(_isPremiumKey, false);
      await prefs.remove(_planNameKey);
      await prefs.remove(_nextBillingDateKey);
    }
    await prefs.setInt(_lastSeenBuildKey, buildNumber);

    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
    _isPremium = prefs.getBool(_isPremiumKey) ?? false;
    _freeEntriesUsed = prefs.getInt(_freeEntriesUsedKey) ?? 0;
    _userName = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
    _userPhotoUrl = prefs.getString(_userPhotoKey);
    _planName = prefs.getString(_planNameKey);
    _nextBillingDate = prefs.getString(_nextBillingDateKey);
    _authProvider = prefs.getString(_authProviderKey);
    notifyListeners();
  }

  Future<void> markOnboardingCompleted() async {
    _onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _onboardingCompleted = false;
    _freeEntriesUsed = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.setInt(_freeEntriesUsedKey, 0);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    // Keep Google sign-in Android-only. On iOS the native Google Sign-In
    // plugin requires extra iOS configuration (URL scheme / Firebase) that
    // is not set up here, and calling it crashes the app.
    if (!kIsWeb && Platform.isIOS) {
      debugPrint('Google sign-in disabled on iOS.');
      return false;
    }
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
      _authProvider = providerGoogle;

      await _persistUser();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final composedName = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      final displayName = composedName.isEmpty ? null : composedName;

      final api = ApiClient();
      try {
        final backendResult = await api.post('/api/auth/apple', {
          'identity_token': credential.identityToken ?? '',
          'authorization_code': credential.authorizationCode,
          'user_identifier': credential.userIdentifier,
          'name': displayName,
          'email': credential.email,
        });
        await api.setToken(backendResult['access_token'] as String);
      } catch (_) {
        // Backend may not be available yet — save locally, sync later
      }

      _userName = displayName ?? _userName;
      _userEmail = credential.email ?? _userEmail;
      _userPhotoUrl = null;
      _isLoggedIn = true;
      _authProvider = providerApple;

      await _persistUser();
      notifyListeners();
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled or other auth error — not a crash
      debugPrint('Apple sign-in authorization error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await ApiClient().clearToken();
    ApiClient().ensureAuthenticated().catchError((_) {});

    _userName = null;
    _userEmail = null;
    _userPhotoUrl = null;
    _isLoggedIn = false;
    _authProvider = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhotoKey);
    await prefs.remove(_authProviderKey);
    await prefs.setBool(_isLoggedInKey, false);

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final api = ApiClient();

    if (api.isAuthenticated) {
      await api.delete('/api/auth/me');
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await AppDatabase.getInstance().then((db) => db.clearUserData());
    await api.clearToken();

    _userName = null;
    _userEmail = null;
    _userPhotoUrl = null;
    _isLoggedIn = false;
    _onboardingCompleted = false;
    _isPremium = false;
    _freeEntriesUsed = 0;
    _planName = null;
    _nextBillingDate = null;
    _authProvider = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhotoKey);
    await prefs.remove(_authProviderKey);
    await prefs.remove(_planNameKey);
    await prefs.remove(_nextBillingDateKey);
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.setBool(_isPremiumKey, false);
    await prefs.setInt(_freeEntriesUsedKey, 0);

    notifyListeners();
  }

  Future<void> incrementFreeEntry() async {
    _freeEntriesUsed++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_freeEntriesUsedKey, _freeEntriesUsed);
    notifyListeners();
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    if (_userName != null) {
      await prefs.setString(_userNameKey, _userName!);
    } else {
      await prefs.remove(_userNameKey);
    }
    if (_userEmail != null) {
      await prefs.setString(_userEmailKey, _userEmail!);
    } else {
      await prefs.remove(_userEmailKey);
    }
    if (_userPhotoUrl != null) {
      await prefs.setString(_userPhotoKey, _userPhotoUrl!);
    } else {
      await prefs.remove(_userPhotoKey);
    }
    if (_authProvider != null) {
      await prefs.setString(_authProviderKey, _authProvider!);
    } else {
      await prefs.remove(_authProviderKey);
    }
  }

  Future<void> setPremium({required bool isPremium, String? planName}) async {
    _isPremium = isPremium;
    _planName = planName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, isPremium);
    if (planName != null) {
      await prefs.setString(_planNameKey, planName);
    }
    notifyListeners();
  }

  Future<void> skipLogin() async {
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    notifyListeners();

    // Background API auth — don't block app startup
    ApiClient().ensureAuthenticated().catchError((_) {});
  }
}
