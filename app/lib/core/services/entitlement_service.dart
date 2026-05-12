import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/services/device_id_service.dart';

/// Server-driven premium-access state, replacing the old local
/// `is_premium` boolean that never expired.
///
/// The server is the source of truth (`GET /api/iap/entitlement`).
/// We keep a local copy in SharedPreferences only as an offline cache:
/// fresh-cached state is trusted for [_cacheTtl] so the UI doesn't
/// flicker between launches; older cache is ignored on startup until
/// the server answers.
///
/// Refresh triggers:
///   * app start (after read-from-cache)
///   * resume from background
///   * after a successful purchase / restore via `/verify`
///   * after sign-in via `/link`
///   * after promo redemption via `/promo/redeem`
class EntitlementService extends ChangeNotifier {
  static final EntitlementService _instance = EntitlementService._();
  factory EntitlementService() => _instance;
  EntitlementService._();

  // ---------------------------------------------------------------------------
  // Persisted cache
  // ---------------------------------------------------------------------------
  static const String _prefsCacheKey = 'entitlement_cache_v1';
  static const String _prefsSyncedAtKey = 'entitlement_synced_at_v1';

  // Legacy SharedPreferences keys from the pre-server era. We read them
  // exactly once on init to migrate stale promo grants forward, then
  // delete them so no future caller is tempted to trust them.
  static const String _legacyIsPremiumKey = 'is_premium';
  static const String _legacyPlanNameKey = 'plan_name';
  static const String _legacyNextBillingDateKey = 'next_billing_date';

  /// Trust the cache (don't fall back to "no premium" before server
  /// answers) for this long after the last successful sync. A week is
  /// generous but matches Apple's grace window for billing retries.
  static const Duration _cacheTtl = Duration(days: 7);

  // ---------------------------------------------------------------------------
  // State (observed by widgets via ChangeNotifier)
  // ---------------------------------------------------------------------------
  bool _isActive = false;
  String? _plan; // 'weekly' | 'yearly' | 'promo_lifetime'
  String? _store; // 'apple' | 'google' | 'promo'
  String? _productId;
  DateTime? _expiresAt;
  bool? _autoRenewEnabled;
  bool? _isInTrial;
  bool? _isInGracePeriod;
  String? _environment; // 'production' | 'sandbox'
  DateTime? _lastSyncedAt;
  bool _initialized = false;

  bool get isActive => _isActive;
  String? get plan => _plan;
  String? get store => _store;
  String? get productId => _productId;
  DateTime? get expiresAt => _expiresAt;
  bool? get autoRenewEnabled => _autoRenewEnabled;
  bool? get isInTrial => _isInTrial;
  bool? get isInGracePeriod => _isInGracePeriod;
  String? get environment => _environment;
  bool get initialized => _initialized;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    // Make sure the device id is ready — every IAP call needs it.
    await DeviceIdService.getOrCreate();
    await _loadFromCache();
    _initialized = true;
    notifyListeners();
    // Fire-and-forget refresh from the server. UI can render immediately
    // from cache; the server answer arrives a beat later.
    unawaited(refresh());
    // One-shot legacy migration: re-redeem old promo grants and StoreKit
    // restore picks up the rest. Always wipes legacy keys at the end.
    unawaited(_migrateLegacyPrefs());
  }

  /// Old builds stored a boolean `is_premium` flag locally that never
  /// expired — the original bug we're fixing. Pre-migration users may
  /// have:
  ///   * `is_premium=true` from a promo redemption with a `plan_name`
  ///     like `promo_8259` (no Apple/Play receipt to restore from).
  ///   * `is_premium=true` from an Apple/Play subscription — silent
  ///     restorePurchases() in [SubscriptionService.init] will re-deliver
  ///     it and trigger /verify, no migration needed here.
  /// Only the first case needs explicit migration: extract the code,
  /// re-redeem on the server, then delete the legacy keys.
  Future<void> _migrateLegacyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final wasPremium = prefs.getBool(_legacyIsPremiumKey) ?? false;
    final legacyPlan = prefs.getString(_legacyPlanNameKey);

    if (wasPremium &&
        legacyPlan != null &&
        legacyPlan.startsWith('promo_')) {
      final code = legacyPlan.substring('promo_'.length);
      if (code.isNotEmpty) {
        try {
          await redeemPromo(code);
        } on ApiException catch (e) {
          // 404 means the server no longer accepts this code (admin
          // pruned it from PROMO_CODES). Nothing to retry; drop keys.
          if (e.statusCode != 404) {
            debugPrint('Legacy promo migration transient error: $e');
            return; // keep keys, retry on next launch
          }
        } catch (e) {
          debugPrint('Legacy promo migration network error: $e');
          return; // keep keys, retry on next launch
        }
      }
    }

    await prefs.remove(_legacyIsPremiumKey);
    await prefs.remove(_legacyPlanNameKey);
    await prefs.remove(_legacyNextBillingDateKey);
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsCacheKey);
    final syncedAtMs = prefs.getInt(_prefsSyncedAtKey);
    _lastSyncedAt = syncedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(syncedAtMs)
        : null;

    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _applyServerState(map);
    } catch (_) {
      // Stale / corrupt cache — ignore.
    }

    // Stale cache: drop the active flag until we can confirm with the
    // server. Plan/expires fields are kept so the UI can still display
    // "expired on …" without a network round trip.
    if (_lastSyncedAt != null &&
        DateTime.now().difference(_lastSyncedAt!) > _cacheTtl) {
      _isActive = false;
    }
  }

  Future<void> _writeCache(Map<String, dynamic> serverState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsCacheKey, jsonEncode(serverState));
    await prefs.setInt(
      _prefsSyncedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    _lastSyncedAt = DateTime.now();
  }

  /// Wipe local state — called on account deletion / logout-with-reset.
  Future<void> clear() async {
    _isActive = false;
    _plan = null;
    _store = null;
    _productId = null;
    _expiresAt = null;
    _autoRenewEnabled = null;
    _isInTrial = null;
    _isInGracePeriod = null;
    _environment = null;
    _lastSyncedAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsCacheKey);
    await prefs.remove(_prefsSyncedAtKey);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Network — server is the source of truth
  // ---------------------------------------------------------------------------

  /// Refresh from `GET /api/iap/entitlement`. Safe to call as often as
  /// needed; no internal debouncing (the call is cheap and not on a hot
  /// path). On failure the cached state is kept untouched.
  Future<void> refresh() async {
    try {
      final token = await DeviceIdService.getOrCreate();
      final response = await ApiClient().get(
        '/api/iap/entitlement',
        params: {'app_account_token': token},
      );
      _applyServerState(response);
      await _writeCache(response);
      notifyListeners();
    } catch (e) {
      debugPrint('EntitlementService.refresh failed: $e');
    }
  }

  /// Send a freshly-completed purchase to `/api/iap/verify`. Returns the
  /// resulting entitlement state. Updates internal state on success.
  Future<bool> verifyPurchase({
    required String store,
    required String productId,
    required String serverVerificationData,
    String? environmentHint,
  }) async {
    try {
      final token = await DeviceIdService.getOrCreate();
      final response = await ApiClient().post('/api/iap/verify', {
        'store': store,
        'product_id': productId,
        'server_verification_data': serverVerificationData,
        'app_account_token': token,
        if (environmentHint != null) 'environment_hint': environmentHint,
      });
      _applyServerState(response);
      await _writeCache(response);
      notifyListeners();
      return _isActive;
    } catch (e) {
      debugPrint('EntitlementService.verifyPurchase failed: $e');
      return false;
    }
  }

  /// Bind any anonymous purchases on this device to the now-logged-in
  /// user. Idempotent — calling repeatedly is harmless.
  Future<void> linkAfterLogin() async {
    try {
      final token = await DeviceIdService.getOrCreate();
      final response = await ApiClient().post('/api/iap/link', {
        'app_account_token': token,
      });
      final entitlement = response['entitlement'] as Map<String, dynamic>?;
      if (entitlement != null) {
        _applyServerState(entitlement);
        await _writeCache(entitlement);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('EntitlementService.linkAfterLogin failed: $e');
    }
  }

  /// Server-side promo redemption (replaces the hard-coded `8259` /
  /// `2170` list that used to live in the paywall screen). Throws
  /// [ApiException] on failure so the caller can distinguish "code
  /// rejected" (status 404) from a network / server problem.
  Future<bool> redeemPromo(String code) async {
    final token = await DeviceIdService.getOrCreate();
    final response = await ApiClient().post('/api/iap/promo/redeem', {
      'code': code,
      'app_account_token': token,
    });
    _applyServerState(response);
    await _writeCache(response);
    notifyListeners();
    return _isActive;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------
  void _applyServerState(Map<String, dynamic> state) {
    _isActive = state['is_active'] == true;
    _plan = state['plan'] as String?;
    _store = state['store'] as String?;
    _productId = state['product_id'] as String?;
    _expiresAt = _parseServerDate(state['expires_at'] as String?);
    _autoRenewEnabled = state['auto_renew_enabled'] as bool?;
    _isInTrial = state['is_in_trial'] as bool?;
    _isInGracePeriod = state['is_in_grace_period'] as bool?;
    _environment = state['environment'] as String?;
  }

  /// The backend stores expiry as naive UTC and FastAPI serializes it
  /// without a 'Z' suffix. Dart's `DateTime.tryParse` then treats it as
  /// local time, which shifts the displayed date by hours for users
  /// outside UTC. Append 'Z' so we always interpret it as UTC and let
  /// the UI explicitly call `toLocal()` when it needs to render.
  static DateTime? _parseServerDate(String? raw) {
    if (raw == null) return null;
    final hasTz = raw.endsWith('Z') || raw.contains('+') || raw.lastIndexOf('-') > 10;
    return DateTime.tryParse(hasTz ? raw : '${raw}Z');
  }
}
