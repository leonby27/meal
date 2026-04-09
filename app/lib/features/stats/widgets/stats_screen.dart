import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late AppDatabase _db;
  bool _dbReady = false;
  List<_DaySummary> _weekData = [];

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadWeekData();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _loadWeekData() async {
    final now = DateTime.now();
    final data = <_DaySummary>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logs = await _db.getFoodLogsForDate(date);
      data.add(_DaySummary(
        date: date,
        calories: logs.fold(0.0, (s, l) => s + l.calories),
        protein: logs.fold(0.0, (s, l) => s + l.protein),
        fat: logs.fold(0.0, (s, l) => s + l.fat),
        carbs: logs.fold(0.0, (s, l) => s + l.carbs),
      ));
    }

    _weekData = data;
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avgCalories = _weekData.isEmpty
        ? 0.0
        : _weekData.fold(0.0, (s, d) => s + d.calories) / _weekData.length;
    final avgProtein = _weekData.isEmpty
        ? 0.0
        : _weekData.fold(0.0, (s, d) => s + d.protein) / _weekData.length;
    final avgFat = _weekData.isEmpty
        ? 0.0
        : _weekData.fold(0.0, (s, d) => s + d.fat) / _weekData.length;
    final avgCarbs = _weekData.isEmpty
        ? 0.0
        : _weekData.fold(0.0, (s, d) => s + d.carbs) / _weekData.length;

    final maxCalories = _weekData.isEmpty
        ? 1.0
        : _weekData.map((d) => d.calories).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Среднее за неделю',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem('Ккал', avgCalories.toInt().toString(), Colors.deepOrange),
                      _StatItem('Белки', '${avgProtein.toStringAsFixed(1)} г', Colors.blue),
                      _StatItem('Жиры', '${avgFat.toStringAsFixed(1)} г', Colors.orange),
                      _StatItem('Углеводы', '${avgCarbs.toStringAsFixed(1)} г', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Калории за неделю',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _weekData.map((day) {
                        final height = (day.calories / maxCalories * 140).clamp(4.0, 140.0);
                        final isToday = DateFormat('yyyy-MM-dd').format(day.date) ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  day.calories > 0 ? day.calories.toInt().toString() : '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary.withAlpha(100),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('E', 'ru').format(day.date).substring(0, 2),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isToday ? FontWeight.bold : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('По дням', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._weekData.reversed.map((day) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(DateFormat('EEEE, d MMM', 'ru').format(day.date)),
                    subtitle: Text(
                      'Б ${day.protein.toStringAsFixed(1)}  '
                      'Ж ${day.fat.toStringAsFixed(1)}  '
                      'У ${day.carbs.toStringAsFixed(1)}',
                    ),
                    trailing: Text(
                      '${day.calories.toInt()} ккал',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DaySummary {
  final DateTime date;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  _DaySummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}
