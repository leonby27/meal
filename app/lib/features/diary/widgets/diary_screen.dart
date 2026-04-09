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

  void _showAddMealSheet(String dateStr) {
    String selectedMealType = 'breakfast';

    const mealTypes = [
      (key: 'breakfast', label: 'Завтрак', icon: Icons.wb_sunny_outlined),
      (key: 'lunch', label: 'Обед', icon: Icons.wb_cloudy_outlined),
      (key: 'dinner', label: 'Ужин', icon: Icons.nights_stay_outlined),
      (key: 'snack', label: 'Перекус', icon: Icons.cookie_outlined),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Добавить приём пищи',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Приём пищи',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: mealTypes.map((m) {
                        final selected = selectedMealType == m.key;
                        return ChoiceChip(
                          avatar: Icon(m.icon, size: 18),
                          label: Text(m.label),
                          selected: selected,
                          onSelected: (_) {
                            setSheetState(() => selectedMealType = m.key);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Способ добавления',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.search,
                      label: 'Найти в базе',
                      subtitle: 'Поиск среди 5500+ продуктов',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/search?meal_type=$selectedMealType&date=$dateStr');
                      },
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.camera_alt,
                      label: 'Сфотографировать',
                      subtitle: 'AI распознает блюдо по фото',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/camera?meal_type=$selectedMealType&date=$dateStr&source=camera');
                      },
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.photo_library,
                      label: 'Выбрать из галереи',
                      subtitle: 'Загрузить фото из галереи',
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/camera?meal_type=$selectedMealType&date=$dateStr&source=gallery');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
          final grouped = {
            'breakfast': logs.where((l) => l.mealType == 'breakfast').toList(),
            'lunch': logs.where((l) => l.mealType == 'lunch').toList(),
            'dinner': logs.where((l) => l.mealType == 'dinner').toList(),
            'snack': logs.where((l) => l.mealType == 'snack').toList(),
          };

          const sections = [
            (key: 'breakfast', title: 'Завтрак', icon: Icons.wb_sunny_outlined),
            (key: 'lunch', title: 'Обед', icon: Icons.wb_cloudy_outlined),
            (key: 'dinner', title: 'Ужин', icon: Icons.nights_stay_outlined),
            (key: 'snack', title: 'Перекус', icon: Icons.cookie_outlined),
          ];

          final nonEmpty = sections.where((s) => grouped[s.key]!.isNotEmpty).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              DailySummaryCard(logs: logs),
              if (nonEmpty.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Нет записей за этот день',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Нажмите кнопку ниже, чтобы добавить приём пищи',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...nonEmpty.map((s) => MealSection(
                title: s.title,
                icon: s.icon,
                mealType: s.key,
                logs: grouped[s.key]!,
                dateStr: dateStr,
                onDelete: (id) => _db.deleteFoodLog(id),
              )),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            onPressed: () => _showAddMealSheet(dateStr),
            icon: const Icon(Icons.add),
            label: const Text('Добавить'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
