import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

/// Wraps the AppsFlyer SDK. AppsFlyer is the MMP we use for attribution and
/// for fanning install/purchase events into TikTok For Business (and any
/// other ad network we wire up later) through their Self-Attributing
/// Network integration.
///
/// The dev key arrives at compile-time via `--dart-define=APPSFLYER_DEV_KEY=…`
/// (see app/.env, threaded by run.sh / build-ipa.sh). If the key is missing
/// we degrade to a no-op — that's the case for `flutter test` runs and for
/// anyone who clones the repo without an .env, so we don't want it to crash.
class AppsFlyerService {
  AppsFlyerService._();
  static final AppsFlyerService instance = AppsFlyerService._();

  static const String _devKey = String.fromEnvironment(
    'APPSFLYER_DEV_KEY',
    defaultValue: '',
  );

  // App Store numeric ID for "BodyMeal AI: Calories by Photo". Required by the
  // iOS AppsFlyer SDK; ignored on Android (where AppsFlyer reads the package
  // name automatically).
  static const String _iosAppId = '6762765278';

  AppsflyerSdk? _sdk;
  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> init() async {
    if (_devKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'AppsFlyer: dev key missing — SDK disabled. '
          'Set APPSFLYER_DEV_KEY in app/.env to enable.',
        );
      }
      return;
    }

    try {
      // `timeToWaitForATTUserAuthorization` defers the first install event
      // for N seconds so the SDK can pick up IDFA once the user has answered
      // the ATT prompt. Our ATT prompt fires at the onboarding result step
      // (post-loading screen), so we need to wait long enough to cover a
      // typical onboarding pass; 90 s is the AppsFlyer-recommended ceiling
      // for plans that gate ATT behind onboarding. Beyond that the install
      // is reported without IDFA — SKAdNetwork still gives us iOS install
      // attribution, just without deterministic IDFA-based matching.
      final options = AppsFlyerOptions(
        afDevKey: _devKey,
        appId: _iosAppId,
        showDebug: kDebugMode,
        timeToWaitForATTUserAuthorization: 90,
      );

      final sdk = AppsflyerSdk(options);
      await sdk.initSdk(
        registerConversionDataCallback: false,
        registerOnAppOpenAttributionCallback: false,
        registerOnDeepLinkingCallback: false,
      );
      _sdk = sdk;
      _enabled = true;

      if (kDebugMode) debugPrint('AppsFlyer: initialised');
    } catch (e) {
      if (kDebugMode) debugPrint('AppsFlyer init failed: $e');
    }
  }

  /// Ties AppsFlyer-side events to the same per-install UUID we use in
  /// Firebase ([DeviceIdService.getOrCreate]) so joining the two datasets
  /// later is a single key match.
  void setUserId(String userId) {
    final sdk = _sdk;
    if (!_enabled || sdk == null) return;
    try {
      sdk.setCustomerUserId(userId);
    } catch (e) {
      if (kDebugMode) debugPrint('AppsFlyer setCustomerUserId failed: $e');
    }
  }

  /// `af_purchase` with revenue & currency — the event TikTok Ads (and other
  /// networks) optimise toward. AppsFlyer dedupes by order id; we pass the
  /// StoreKit transaction id so a replayed `.purchased` transaction on cold
  /// start does not double-count.
  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    required String productId,
  }) {
    return _log('af_purchase', {
      'af_revenue': value,
      'af_currency': currency,
      'af_content_id': productId,
      'af_order_id': transactionId,
      'af_quantity': 1,
    });
  }

  /// `af_initiated_checkout` — paywall CTA tap. Useful as a mid-funnel
  /// optimisation event when purchase volume is too low for the algorithm
  /// to learn from.
  Future<void> logBeginCheckout({
    required double value,
    required String currency,
    required String productId,
  }) {
    return _log('af_initiated_checkout', {
      'af_revenue': value,
      'af_currency': currency,
      'af_content_id': productId,
      'af_quantity': 1,
    });
  }

  /// `af_start_trial` — fires only for the yearly plan (the only product
  /// sold with a free intro trial). Independent from `af_purchase` so trial
  /// conversion can be optimised separately from paid conversion.
  Future<void> logTrialStart({
    required String transactionId,
    required double value,
    required String currency,
    required String productId,
  }) {
    return _log('af_start_trial', {
      'af_revenue': value,
      'af_currency': currency,
      'af_content_id': productId,
      'af_order_id': transactionId,
    });
  }

  /// `af_content_view` — paywall impression. Higher-frequency upper-funnel
  /// signal that helps the algorithm find users likely to reach the paywall.
  Future<void> logPaywallView({String? source}) {
    return _log('af_content_view', {
      'af_content_type': 'paywall',
      if (source != null) 'af_content_id': source,
    });
  }

  Future<void> _log(String name, Map<String, dynamic> params) async {
    final sdk = _sdk;
    if (!_enabled || sdk == null) {
      if (kDebugMode) debugPrint('AppsFlyer skipped: $name $params');
      return;
    }
    try {
      await sdk.logEvent(name, params);
    } catch (e) {
      if (kDebugMode) debugPrint('AppsFlyer logEvent failed: $name $e');
    }
  }
}
