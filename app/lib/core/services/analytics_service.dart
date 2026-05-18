import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:meal_tracker/core/services/appsflyer_service.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _enabled = false;
  bool _attRequested = false;

  FirebaseAnalytics? get analytics => _analytics;

  Future<void> init() async {
    _analytics = FirebaseAnalytics.instance;
    _enabled = true;
    await _analytics!.setAnalyticsCollectionEnabled(true);
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics skipped: $name ${parameters ?? {}}');
      }
      return;
    }

    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics logEvent failed: $name $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Standard ecommerce events (feed Firebase Revenue / LTV dashboards + Google
  // Ads attribution). Names and parameter shapes are fixed by Firebase — using
  // typed wrappers so we never typo a parameter key and silently lose data.
  // ---------------------------------------------------------------------------

  Future<void> logViewItemList({
    required List<AnalyticsEventItem> items,
    String? itemListId,
    String? itemListName,
  }) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics skipped: view_item_list items=${items.length}');
      }
      return;
    }
    try {
      await analytics.logViewItemList(
        items: items,
        itemListId: itemListId,
        itemListName: itemListName,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics logViewItemList failed: $e');
    }
  }

  Future<void> logSelectItem({
    required List<AnalyticsEventItem> items,
    String? itemListId,
    String? itemListName,
  }) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics skipped: select_item items=${items.length}');
      }
      return;
    }
    try {
      await analytics.logSelectItem(
        items: items,
        itemListId: itemListId,
        itemListName: itemListName,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics logSelectItem failed: $e');
    }
  }

  Future<void> logBeginCheckout({
    required double value,
    required String currency,
    required List<AnalyticsEventItem> items,
    String? coupon,
  }) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics skipped: begin_checkout value=$value $currency');
      }
    } else {
      try {
        await analytics.logBeginCheckout(
          value: value,
          currency: currency,
          items: items,
          coupon: coupon,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Analytics logBeginCheckout failed: $e');
      }
    }

    final firstItem = items.isNotEmpty ? items.first : null;
    if (firstItem != null) {
      await AppsFlyerService.instance.logBeginCheckout(
        value: value,
        currency: currency,
        productId: firstItem.itemId ?? '',
      );
    }
  }

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
    required List<AnalyticsEventItem> items,
    String? coupon,
  }) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) {
        debugPrint(
          'Analytics skipped: purchase tx=$transactionId value=$value $currency',
        );
      }
    } else {
      try {
        await analytics.logPurchase(
          transactionId: transactionId,
          value: value,
          currency: currency,
          items: items,
          coupon: coupon,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Analytics logPurchase failed: $e');
      }
    }

    final firstItem = items.isNotEmpty ? items.first : null;
    if (firstItem != null) {
      await AppsFlyerService.instance.logPurchase(
        transactionId: transactionId,
        value: value,
        currency: currency,
        productId: firstItem.itemId ?? '',
      );
    }
  }

  /// Paywall impression. Feeds Firebase as a custom event AND AppsFlyer's
  /// `af_content_view` so TikTok/other networks can optimise toward
  /// paywall-reach (a higher-frequency upper-funnel signal than purchase).
  Future<void> logPaywallView({String? planId}) async {
    await logEvent(
      'paywall_viewed',
      parameters: planId == null ? null : {'plan': planId},
    );
    await AppsFlyerService.instance.logPaywallView(source: planId);
  }

  /// Trial start (yearly plan only — weekly has no intro trial). Fires the
  /// Firebase-recommended `start_trial` event AND AppsFlyer's `af_start_trial`
  /// so trial-conversion campaigns can optimise independently from paid
  /// purchases.
  Future<void> logStartTrial({
    required String transactionId,
    required double price,
    required String currency,
    required String productId,
  }) async {
    await logEvent(
      'start_trial',
      parameters: {
        'currency': currency,
        'price': price,
        'product_id': productId,
        'transaction_id': transactionId,
      },
    );
    await AppsFlyerService.instance.logTrialStart(
      transactionId: transactionId,
      value: price,
      currency: currency,
      productId: productId,
    );
  }

  // ---------------------------------------------------------------------------
  // User identity + properties
  //
  // Firebase keeps user properties separate from event parameters; they live
  // with the user (not the event) and let dashboards slice events by stable
  // user traits like goal, gender, locale, subscription status. Names are
  // capped at 24 chars, values at 36 chars; reserved prefixes `firebase_`,
  // `google_`, `ga_` must be avoided.
  // ---------------------------------------------------------------------------

  Future<void> setUserId(String? userId) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) debugPrint('Analytics skipped: setUserId=$userId');
      return;
    }
    try {
      await analytics.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics setUserId failed: $e');
    }
  }

  Future<void> setUserProperty(String name, String? value) async {
    final analytics = _analytics;
    if (!_enabled || analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics skipped: setUserProperty $name=$value');
      }
      return;
    }
    try {
      // Firebase rejects values longer than 36 chars silently — truncate
      // upfront so we never lose a property to a typo or accidental long
      // string (e.g. a localized goal label slipping in instead of the key).
      final truncated = value != null && value.length > 36
          ? value.substring(0, 36)
          : value;
      await analytics.setUserProperty(name: name, value: truncated);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics setUserProperty failed: $e');
    }
  }

  Future<void> setUserProperties(Map<String, String?> properties) async {
    for (final entry in properties.entries) {
      await setUserProperty(entry.key, entry.value);
    }
  }

  // ---------------------------------------------------------------------------
  // App Tracking Transparency (iOS only)
  //
  // The system tracking-authorization prompt can only be shown once per
  // install — after that, [requestTrackingAuthorization] returns the same
  // status without re-prompting. We gate by [_attRequested] so a second
  // call within the same session is a no-op even before the OS response
  // lands. The result is recorded as a user property so we can compare
  // retention/conversion across the authorization buckets.
  // ---------------------------------------------------------------------------

  Future<void> requestAttPermissionIfNeeded() async {
    if (_attRequested) return;
    _attRequested = true;

    if (!Platform.isIOS) {
      await setUserProperty('att_status', 'not_applicable');
      return;
    }

    try {
      final current =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      // If iOS has already resolved the prompt in a previous session
      // (authorized / denied / restricted), don't re-request — just record
      // the current state. Only `notDetermined` triggers the system dialog.
      final status = current == TrackingStatus.notDetermined
          ? await AppTrackingTransparency.requestTrackingAuthorization()
          : current;
      await setUserProperty('att_status', _attStatusLabel(status));
    } catch (e) {
      if (kDebugMode) debugPrint('ATT request failed: $e');
      await setUserProperty('att_status', 'error');
    }
  }

  String _attStatusLabel(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.authorized:
        return 'authorized';
      case TrackingStatus.denied:
        return 'denied';
      case TrackingStatus.restricted:
        return 'restricted';
      case TrackingStatus.notDetermined:
        return 'not_determined';
      case TrackingStatus.notSupported:
        return 'not_supported';
    }
  }
}
