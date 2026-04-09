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
  double _goalProtein = 100;
  double _goalFat = 70;
  double _goalCarbs = 250;
  bool _expanded = false;

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
        _goalProtein = double.tryParse(prot ?? '') ?? 100;
        _goalFat = double.tryParse(fat ?? '') ?? 70;
        _goalCarbs = double.tryParse(carbs ?? '') ?? 250;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = widget.logs.fold(0.0, (sum, l) => sum + l.calories);
    final totalProtein = widget.logs.fold(0.0, (sum, l) => sum + l.protein);
    final totalFat = widget.logs.fold(0.0, (sum, l) => sum + l.fat);
    final totalCarbs = widget.logs.fold(0.0, (sum, l) => sum + l.carbs);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ProgressRow(
                    label: 'Ккал',
                    current: totalCalories,
                    goal: _goalCalories,
                    color: Theme.of(context).colorScheme.primary,
                    overColor: Colors.red,
                    barHeight: 8,
                    isBold: true,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    _ProgressRow(
                      label: 'Белки',
                      current: totalProtein,
                      goal: _goalProtein,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _ProgressRow(
                      label: 'Жиры',
                      current: totalFat,
                      goal: _goalFat,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _ProgressRow(
                      label: 'Углеводы',
                      current: totalCarbs,
                      goal: _goalCarbs,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final Color? overColor;
  final double barHeight;
  final bool isBold;

  const _ProgressRow({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    this.overColor,
    this.barHeight = 6,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();
    final isOver = current > goal;
    final activeColor = (isOver && overColor != null) ? overColor! : color;
    final unit = isBold ? '' : ' г';
    final currentText = isBold
        ? current.toInt().toString()
        : current.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label: $currentText из ${goal.toInt()}$unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isOver ? activeColor : null,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isOver ? activeColor : Colors.grey.shade600,
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
            valueColor: AlwaysStoppedAnimation(activeColor),
            minHeight: barHeight,
          ),
        ),
      ],
    );
  }
}
