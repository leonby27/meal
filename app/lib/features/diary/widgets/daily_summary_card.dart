import 'package:flutter/material.dart';
import 'package:meal_tracker/core/database/app_database.dart';

class DailySummaryCard extends StatefulWidget {
  final List<FoodLog> logs;

  const DailySummaryCard({super.key, required this.logs});

  @override
  State<DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard> {
  double _goalCalories = 2000;
  double? _goalProtein;
  double? _goalFat;
  double? _goalCarbs;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final db = await AppDatabase.getInstance();
    final cal = await db.getSetting('calorie_goal');
    final prot = await db.getSetting('protein_goal');
    final fat = await db.getSetting('fat_goal');
    final carbs = await db.getSetting('carbs_goal');
    if (mounted) {
      setState(() {
        _goalCalories = double.tryParse(cal ?? '') ?? 2000;
        _goalProtein = double.tryParse(prot ?? '');
        _goalFat = double.tryParse(fat ?? '');
        _goalCarbs = double.tryParse(carbs ?? '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = widget.logs.fold(0.0, (sum, l) => sum + l.calories);
    final totalProtein = widget.logs.fold(0.0, (sum, l) => sum + l.protein);
    final totalFat = widget.logs.fold(0.0, (sum, l) => sum + l.fat);
    final totalCarbs = widget.logs.fold(0.0, (sum, l) => sum + l.carbs);
    final remaining = (_goalCalories - totalCalories).clamp(0, double.infinity);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: (totalCalories / _goalCalories).clamp(0, 1),
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalCalories > _goalCalories
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            totalCalories.toInt().toString(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'из ${_goalCalories.toInt()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
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
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Осталось',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '${remaining.toInt()} ккал',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: totalCalories > _goalCalories ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MacroProgressBar(
                    label: 'Белки',
                    current: totalProtein,
                    goal: _goalProtein,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroProgressBar(
                    label: 'Жиры',
                    current: totalFat,
                    goal: _goalFat,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroProgressBar(
                    label: 'Углеводы',
                    current: totalCarbs,
                    goal: _goalCarbs,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double? goal;
  final Color color;

  const _MacroProgressBar({
    required this.label,
    required this.current,
    this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasGoal = goal != null && goal! > 0;
    final progress = hasGoal ? (current / goal!).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          '${current.toStringAsFixed(1)} г',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (hasGoal) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'из ${goal!.toInt()} г',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
