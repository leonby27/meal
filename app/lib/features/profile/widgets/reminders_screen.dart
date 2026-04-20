import 'package:flutter/material.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/notification_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class _ReminderConfig {
  final String key;
  final IconData icon;
  final TimeOfDay defaultTime;

  const _ReminderConfig({
    required this.key,
    required this.icon,
    required this.defaultTime,
  });
}

const _reminders = [
  _ReminderConfig(key: 'breakfast', icon: Icons.wb_sunny_outlined, defaultTime: TimeOfDay(hour: 8, minute: 30)),
  _ReminderConfig(key: 'lunch', icon: Icons.wb_cloudy_outlined, defaultTime: TimeOfDay(hour: 13, minute: 0)),
  _ReminderConfig(key: 'dinner', icon: Icons.nights_stay_outlined, defaultTime: TimeOfDay(hour: 19, minute: 0)),
  _ReminderConfig(key: 'snack', icon: Icons.cookie_outlined, defaultTime: TimeOfDay(hour: 16, minute: 0)),
];

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  final Map<String, TimeOfDay?> _times = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _db = await AppDatabase.getInstance();
    await NotificationService.init();

    for (final r in _reminders) {
      final val = await _db.getSetting('reminder_${r.key}');
      if (val != null && val.isNotEmpty && val.contains(':')) {
        final parts = val.split(':');
        _times[r.key] = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _toggleReminder(String key, bool enabled, TimeOfDay defaultTime) async {
    if (enabled) {
      await NotificationService.requestPermissions();
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: _times[key] ?? defaultTime,
      );
      if (time == null) return;
      await NotificationService.scheduleMealReminder(key, time.hour, time.minute);
      setState(() => _times[key] = time);
    } else {
      await NotificationService.cancelMealReminder(key);
      setState(() => _times.remove(key));
    }
  }

  Future<void> _changeTime(String key) async {
    final current = _times[key];
    if (current == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (time == null) return;

    await NotificationService.scheduleMealReminder(key, time.hour, time.minute);
    setState(() => _times[key] = time);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _reminderLabel(BuildContext context, String key) {
    switch (key) {
      case 'breakfast': return context.l10n.mealBreakfast;
      case 'lunch':     return context.l10n.mealLunch;
      case 'dinner':    return context.l10n.mealDinner;
      case 'snack':     return context.l10n.mealSnack;
      default:          return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.remindersTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: _reminders.map((r) {
                  final isEnabled = _times.containsKey(r.key);
                  return ListTile(
                    leading: Icon(r.icon),
                    title: Text(_reminderLabel(context, r.key)),
                    subtitle: isEnabled
                        ? GestureDetector(
                            onTap: () => _changeTime(r.key),
                            child: Text(
                              _formatTime(_times[r.key]!),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Text(context.l10n.reminderOff),
                    trailing: Switch(
                      value: isEnabled,
                      onChanged: (v) => _toggleReminder(r.key, v, r.defaultTime),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.remindersDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
