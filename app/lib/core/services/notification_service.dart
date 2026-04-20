import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _mealIds = {
    'breakfast': 100,
    'lunch': 101,
    'dinner': 102,
    'snack': 103,
  };

  static ({String title, String body}) _mealReminderText(String mealType) {
    final l10n = currentL10n;
    return switch (mealType) {
      'breakfast' => (title: l10n.mealBreakfast, body: l10n.notifBreakfastBody),
      'lunch' => (title: l10n.mealLunch, body: l10n.notifLunchBody),
      'dinner' => (title: l10n.mealDinner, body: l10n.notifDinnerBody),
      'snack' => (title: l10n.mealSnack, body: l10n.notifSnackBody),
      _ => (title: mealType, body: ''),
    };
  }

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> scheduleMealReminder(String mealType, int hour, int minute) async {
    final id = _mealIds[mealType];
    if (id == null) return;

    final text = _mealReminderText(mealType);
    final l10n = currentL10n;

    await _plugin.zonedSchedule(
      id: id,
      title: text.title,
      body: text.body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          l10n.notifChannelName,
          channelDescription: l10n.notifChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final db = await AppDatabase.getInstance();
    await db.setSetting('reminder_$mealType', '$hour:$minute');
  }

  static Future<void> cancelMealReminder(String mealType) async {
    final id = _mealIds[mealType];
    if (id == null) return;
    await _plugin.cancel(id: id);

    final db = await AppDatabase.getInstance();
    await db.setSetting('reminder_$mealType', '');
  }

  static Future<void> restoreReminders() async {
    final db = await AppDatabase.getInstance();
    for (final entry in _mealIds.entries) {
      final val = await db.getSetting('reminder_${entry.key}');
      if (val != null && val.isNotEmpty && val.contains(':')) {
        final parts = val.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        await scheduleMealReminder(entry.key, hour, minute);
      }
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
