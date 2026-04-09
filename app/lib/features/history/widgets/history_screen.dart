import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  List<_HistoryDay> _days = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _load();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _load() async {
    final dates = await _db.getLoggedDates(limit: 90);
    final days = <_HistoryDay>[];

    for (final date in dates) {
      final logs = await _db.getFoodLogsForDate(date);
      if (logs.isEmpty) continue;
      days.add(_HistoryDay(
        date: date,
        totalCalories: logs.fold(0.0, (s, l) => s + l.calories),
        totalProtein: logs.fold(0.0, (s, l) => s + l.protein),
        totalFat: logs.fold(0.0, (s, l) => s + l.fat),
        totalCarbs: logs.fold(0.0, (s, l) => s + l.carbs),
        mealCount: logs.length,
      ));
    }

    _days = days;
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: _days.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Нет записей', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final d = DateTime(day.date.year, day.date.month, day.date.day);

                String dateLabel;
                if (d == today) {
                  dateLabel = 'Сегодня';
                } else if (d == today.subtract(const Duration(days: 1))) {
                  dateLabel = 'Вчера';
                } else {
                  dateLabel = DateFormat('EEEE, d MMMM', 'ru').format(day.date);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(dateLabel),
                    subtitle: Text(
                      '${day.mealCount} записей  •  '
                      'Б ${day.totalProtein.toStringAsFixed(1)} '
                      'Ж ${day.totalFat.toStringAsFixed(1)} '
                      'У ${day.totalCarbs.toStringAsFixed(1)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${day.totalCalories.toInt()}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ккал',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryDay {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalFat;
  final double totalCarbs;
  final int mealCount;

  _HistoryDay({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCarbs,
    required this.mealCount,
  });
}
