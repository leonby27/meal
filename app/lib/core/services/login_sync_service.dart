import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/auth_service.dart';

/// Reconciles pre-login (anonymous) local Drift data with the user's
/// cloud account on sign-in.
///
/// Subscription state is intentionally NOT touched here — it is owned
/// by [EntitlementService] (server-driven, sourced from /api/iap/*)
/// and bound to the device via the install UUID rather than the data
/// sync flow. Sign-in does call `/api/iap/link` separately from
/// [AuthService.signInWith*] to attach any anonymous entitlements to
/// the freshly-authenticated user.
class LoginSyncService {
  LoginSyncService();

  final ApiClient _api = ApiClient();

  Future<bool> hasLocalData() async {
    final db = await AppDatabase.getInstance();
    final logs = await db.select(db.foodLogs).get();
    if (logs.isNotEmpty) return true;
    final settings = await db.select(db.userSettings).get();
    return settings.isNotEmpty;
  }

  Future<void> migrateAndPull() async {
    await _pushLocalFoodLogs();
    await _pushLocalSettingsIfCloudEmpty();
    await _replaceLocalFromCloud();
  }

  Future<void> pullOnly() async {
    await _replaceLocalFromCloud();
  }

  /// Best-effort upsert of a partial settings map on the cloud account.
  /// No-op if the user isn't signed in. Errors are logged but never
  /// rethrown — the caller has already written the settings locally and
  /// shouldn't fail because the network was flaky. Backend's POST
  /// `/api/users/me/settings` is a partial upsert: keys not in the
  /// payload are left untouched.
  Future<void> pushSettings(Map<String, String> settings) async {
    if (!AuthService().isLoggedIn) return;
    if (settings.isEmpty) return;
    try {
      await _api.post('/api/users/me/settings', {'settings': settings});
    } catch (e) {
      debugPrint('LoginSyncService.pushSettings failed: $e');
    }
  }

  Future<void> _pushLocalFoodLogs() async {
    final db = await AppDatabase.getInstance();
    final logs = await db.select(db.foodLogs).get();
    if (logs.isEmpty) return;

    final entries = logs.map(_foodLogToJson).toList();
    await _api.post('/api/sync/push', {'entries': entries});
  }

  Future<void> _pushLocalSettingsIfCloudEmpty() async {
    final cloud = await _getCloudSettings();
    if (cloud.isNotEmpty) return;

    final db = await AppDatabase.getInstance();
    final localRows = await db.select(db.userSettings).get();
    if (localRows.isEmpty) return;

    final payload = <String, String>{
      for (final r in localRows) r.key: r.value,
    };
    await _api.post('/api/users/me/settings', {'settings': payload});
  }

  Future<void> _replaceLocalFromCloud() async {
    final cloudLogs = await _getCloudFoodLogs();
    final cloudSettings = await _getCloudSettings();

    final db = await AppDatabase.getInstance();
    await db.transaction(() async {
      await db.delete(db.foodLogs).go();
      for (final log in cloudLogs) {
        await db.into(db.foodLogs).insert(_foodLogFromJson(log));
      }

      await db.delete(db.userSettings).go();
      for (final entry in cloudSettings.entries) {
        await db.into(db.userSettings).insert(
              UserSettingsCompanion.insert(key: entry.key, value: entry.value),
            );
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getCloudFoodLogs() async {
    final raw = await _api.getList('/api/sync/pull');
    return raw.cast<Map<String, dynamic>>();
  }

  Future<Map<String, String>> _getCloudSettings() async {
    final response = await _api.get('/api/users/me/settings');
    final raw = response['settings'];
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  Map<String, dynamic> _foodLogToJson(FoodLog log) {
    return {
      'id': log.id,
      'product_id': log.productId,
      'product_name': log.productName,
      'meal_type': log.mealType,
      'meal_date': _dateOnly(log.mealDate),
      'grams': log.grams,
      'protein': log.protein,
      'fat': log.fat,
      'carbs': log.carbs,
      'calories': log.calories,
      'image_url': log.imageUrl,
      'ingredients_json': log.ingredientsJson,
      'created_at': log.createdAt.toUtc().toIso8601String(),
      'updated_at': log.updatedAt.toUtc().toIso8601String(),
    };
  }

  FoodLogsCompanion _foodLogFromJson(Map<String, dynamic> json) {
    return FoodLogsCompanion.insert(
      id: json['id'] as String,
      productId: Value<int?>(json['product_id'] as int?),
      productName: json['product_name'] as String,
      mealType: json['meal_type'] as String,
      mealDate: _parseMealDate(json['meal_date']),
      grams: (json['grams'] as num).toDouble(),
      protein: Value((json['protein'] as num?)?.toDouble() ?? 0),
      fat: Value((json['fat'] as num?)?.toDouble() ?? 0),
      carbs: Value((json['carbs'] as num?)?.toDouble() ?? 0),
      calories: Value((json['calories'] as num?)?.toDouble() ?? 0),
      imageUrl: Value(json['image_url'] as String?),
      ingredientsJson: Value(json['ingredients_json'] as String?),
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  /// Parse "YYYY-MM-DD" from the backend as **local** midnight. Using
  /// `DateTime.parse` would treat it as UTC midnight, which then shifts
  /// to the previous local day in negative-UTC timezones (e.g. a US user
  /// would see meals jump from May 6 to May 5 after a sync).
  DateTime _parseMealDate(Object? raw) {
    if (raw is String) {
      final parts = raw.split('T').first.split('-');
      if (parts.length >= 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime.now();
  }

  Value<DateTime> _parseTimestamp(Object? raw) {
    if (raw is String) {
      try {
        return Value(DateTime.parse(raw));
      } catch (_) {}
    }
    return const Value.absent();
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}
