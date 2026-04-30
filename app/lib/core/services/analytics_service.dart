import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _enabled = false;

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
}
