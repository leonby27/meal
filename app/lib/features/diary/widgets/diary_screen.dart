import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/features/diary/widgets/meal_section.dart';
import 'package:meal_tracker/features/diary/widgets/daily_summary_card.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  late AppDatabase _db;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.getInstance();
    if (mounted) setState(() => _dbReady = true);
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _onMenuAction(String action) async {
    if (action == 'copy_day') {
      final target = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        locale: const Locale('ru'),
        helpText: 'Скопировать весь день в…',
      );
      if (target == null || !mounted) return;
      final count = await _db.copyMealLogs(fromDate: _selectedDate, toDate: target);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Скопировано $count записей в ${DateFormat('d MMM', 'ru').format(target)}')),
        );
      }
    } else if (action == 'history') {
      context.push('/history');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Сегодня';
    if (selected == today.subtract(const Duration(days: 1))) return 'Вчера';
    if (selected == today.add(const Duration(days: 1))) return 'Завтра';
    return DateFormat('d MMMM', 'ru').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeDate(-1),
            ),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  locale: const Locale('ru'),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: Text(
                _formatDate(_selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _onMenuAction(action),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'copy_day', child: Text('Копировать день')),
              const PopupMenuItem(value: 'history', child: Text('История')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<FoodLog>>(
        stream: _db.watchFoodLogsForDate(_selectedDate),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          final breakfast = logs.where((l) => l.mealType == 'breakfast').toList();
          final lunch = logs.where((l) => l.mealType == 'lunch').toList();
          final dinner = logs.where((l) => l.mealType == 'dinner').toList();
          final snack = logs.where((l) => l.mealType == 'snack').toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              DailySummaryCard(logs: logs),
              MealSection(
                title: 'Завтрак',
                icon: Icons.wb_sunny_outlined,
                mealType: 'breakfast',
                logs: breakfast,
                dateStr: dateStr,
                onDelete: (id) => _db.deleteFoodLog(id),
              ),
              MealSection(
                title: 'Обед',
                icon: Icons.wb_cloudy_outlined,
                mealType: 'lunch',
                logs: lunch,
                dateStr: dateStr,
                onDelete: (id) => _db.deleteFoodLog(id),
              ),
              MealSection(
                title: 'Ужин',
                icon: Icons.nights_stay_outlined,
                mealType: 'dinner',
                logs: dinner,
                dateStr: dateStr,
                onDelete: (id) => _db.deleteFoodLog(id),
              ),
              MealSection(
                title: 'Перекус',
                icon: Icons.cookie_outlined,
                mealType: 'snack',
                logs: snack,
                dateStr: dateStr,
                onDelete: (id) => _db.deleteFoodLog(id),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/camera?meal_type=snack&date=$dateStr'),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
