import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/meal_type_helper.dart';
import 'package:meal_tracker/features/diary/widgets/meal_section.dart';
import 'package:meal_tracker/features/diary/widgets/daily_summary_card.dart';
import 'package:meal_tracker/features/camera/widgets/camera_screen.dart';

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
    String selectedMealType = defaultMealType();

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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMealType,
                      decoration: const InputDecoration(
                        labelText: 'Приём пищи',
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                      items: mealTypes.map((m) {
                        return DropdownMenuItem(
                          value: m.key,
                          child: Row(
                            children: [
                              Icon(m.icon, size: 20),
                              const SizedBox(width: 8),
                              Text(m.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setSheetState(() => selectedMealType = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactActionTile(
                            icon: Icons.search,
                            label: 'Найти в базе',
                            onTap: () {
                              Navigator.pop(ctx);
                              context.push('/search?meal_type=$selectedMealType&date=$dateStr');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactActionTile(
                            icon: Icons.photo_library_outlined,
                            label: 'Из галереи',
                            onTap: () {
                              Navigator.pop(ctx);
                              CameraScreen.showAsSheet(
                                context,
                                mealType: selectedMealType,
                                dateStr: dateStr,
                                autoSource: 'gallery',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          CameraScreen.showAsSheet(
                            context,
                            mealType: selectedMealType,
                            dateStr: dateStr,
                            autoSource: 'camera',
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Распознать по фото'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 300) {
            _changeDate(-1);
          } else if (velocity < -300) {
            _changeDate(1);
          }
        },
        child: StreamBuilder<List<FoodLog>>(
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

class _CompactActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactActionTile({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
