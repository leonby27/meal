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
  List<_DaySummary> _data = [];
  int _periodDays = 7;
  double _goalCalories = 2000;
  double? _goalProtein;
  double? _goalFat;
  double? _goalCarbs;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    await _loadGoals();
    await _loadData();
    if (mounted) setState(() => _dbReady = true);
  }

  Future<void> _loadGoals() async {
    _goalCalories = double.tryParse(await _db.getSetting('calorie_goal') ?? '') ?? 2000;
    _goalProtein = double.tryParse(await _db.getSetting('protein_goal') ?? '');
    _goalFat = double.tryParse(await _db.getSetting('fat_goal') ?? '');
    _goalCarbs = double.tryParse(await _db.getSetting('carbs_goal') ?? '');
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final data = <_DaySummary>[];

    for (int i = _periodDays - 1; i >= 0; i--) {
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

    _data = data;
  }

  void _setPeriod(int days) async {
    _periodDays = days;
    await _loadData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final daysWithData = _data.where((d) => d.calories > 0).length;
    final avgCalories = daysWithData > 0
        ? _data.fold(0.0, (s, d) => s + d.calories) / daysWithData : 0.0;
    final avgProtein = daysWithData > 0
        ? _data.fold(0.0, (s, d) => s + d.protein) / daysWithData : 0.0;
    final avgFat = daysWithData > 0
        ? _data.fold(0.0, (s, d) => s + d.fat) / daysWithData : 0.0;
    final avgCarbs = daysWithData > 0
        ? _data.fold(0.0, (s, d) => s + d.carbs) / daysWithData : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          _buildGoalProgress(avgCalories, avgProtein, avgFat, avgCarbs),
          const SizedBox(height: 12),
          _buildBarChart('Калории', _data.map((d) => d.calories).toList(), _goalCalories, Colors.deepOrange),
          const SizedBox(height: 12),
          _buildBarChart('Белки (г)', _data.map((d) => d.protein).toList(), _goalProtein, Colors.blue),
          const SizedBox(height: 12),
          _buildBarChart('Жиры (г)', _data.map((d) => d.fat).toList(), _goalFat, Colors.orange),
          const SizedBox(height: 12),
          _buildBarChart('Углеводы (г)', _data.map((d) => d.carbs).toList(), _goalCarbs, Colors.green),
          const SizedBox(height: 12),
          _buildDaysList(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('Неделя')),
        ButtonSegment(value: 14, label: Text('2 недели')),
        ButtonSegment(value: 30, label: Text('Месяц')),
      ],
      selected: {_periodDays},
      onSelectionChanged: (s) => _setPeriod(s.first),
    );
  }

  Widget _buildGoalProgress(double cal, double prot, double fat, double carbs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Среднее в день', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _GoalRow(label: 'Калории', current: cal, goal: _goalCalories, unit: 'ккал', color: Colors.deepOrange),
            if (_goalProtein != null && _goalProtein! > 0)
              _GoalRow(label: 'Белки', current: prot, goal: _goalProtein!, unit: 'г', color: Colors.blue),
            if (_goalFat != null && _goalFat! > 0)
              _GoalRow(label: 'Жиры', current: fat, goal: _goalFat!, unit: 'г', color: Colors.orange),
            if (_goalCarbs != null && _goalCarbs! > 0)
              _GoalRow(label: 'Углеводы', current: carbs, goal: _goalCarbs!, unit: 'г', color: Colors.green),
            if (_goalProtein == null && _goalFat == null && _goalCarbs == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip('Б', '${prot.toStringAsFixed(1)} г', Colors.blue),
                  _StatChip('Ж', '${fat.toStringAsFixed(1)} г', Colors.orange),
                  _StatChip('У', '${carbs.toStringAsFixed(1)} г', Colors.green),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String title, List<double> values, double? goal, Color color) {
    final maxVal = values.isEmpty ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    final chartMax = goal != null && goal > maxVal ? goal * 1.1 : maxVal * 1.1;
    final showLabels = _periodDays <= 14;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  if (goal != null && goal > 0)
                    Positioned(
                      left: 0, right: 0,
                      bottom: (goal / chartMax * 130).clamp(0, 130),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.red.withAlpha(120),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            goal.toInt().toString(),
                            style: TextStyle(fontSize: 9, color: Colors.red.shade300),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(values.length, (i) {
                      final v = values[i];
                      final h = (v / chartMax * 130).clamp(2.0, 130.0);
                      final isToday = i == values.length - 1;
                      final overGoal = goal != null && v > goal;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: _periodDays <= 14 ? 3 : 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (showLabels && v > 0)
                                Text(v.toInt().toString(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
                              const SizedBox(height: 2),
                              Container(
                                height: h,
                                decoration: BoxDecoration(
                                  color: overGoal
                                      ? Colors.red.withAlpha(180)
                                      : isToday ? color : color.withAlpha(120),
                                  borderRadius: BorderRadius.circular(_periodDays <= 14 ? 4 : 2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (showLabels)
                                Text(
                                  DateFormat('E', 'ru').format(_data[i].date).substring(0, 2),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: isToday ? FontWeight.bold : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysList() {
    final recent = _data.reversed.take(7).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('По дням', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...recent.map((day) {
              final overCalories = day.calories > _goalCalories;
              return ListTile(
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: overCalories ? Colors.red : null,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;

  const _GoalRow({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);
    final percent = (current / goal * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${current.toInt()} / ${goal.toInt()} $unit ($percent%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: current > goal ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(current > goal ? Colors.red : color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
