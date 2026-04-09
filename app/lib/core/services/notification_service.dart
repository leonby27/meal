import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:meal_tracker/core/database/app_database.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _mealReminders = {
    'breakfast': (id: 100, title: 'Завтрак', body: 'Время записать завтрак'),
    'lunch': (id: 101, title: 'Обед', body: 'Время записать обед'),
    'dinner': (id: 102, title: 'Ужин', body: 'Время записать ужин'),
    'snack': (id: 103, title: 'Перекус', body: 'Не забудьте записать перекус'),
  };

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
    final reminder = _mealReminders[mealType];
    if (reminder == null) return;

    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'meal_reminders',
          'Напоминания о приемах пищи',
          channelDescription: 'Напоминания записать приемы пищи',
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
    final reminder = _mealReminders[mealType];
    if (reminder == null) return;
    await _plugin.cancel(id: reminder.id);

    final db = await AppDatabase.getInstance();
    await db.setSetting('reminder_$mealType', '');
  }

  static Future<void> restoreReminders() async {
    final db = await AppDatabase.getInstance();
    for (final entry in _mealReminders.entries) {
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
