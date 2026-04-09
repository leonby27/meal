import 'package:flutter/material.dart';
import 'package:meal_tracker/core/database/app_database.dart';

class DailySummaryCard extends StatelessWidget {
  final List<FoodLog> logs;

  const DailySummaryCard({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final totalCalories = logs.fold(0.0, (sum, l) => sum + l.calories);
    final totalProtein = logs.fold(0.0, (sum, l) => sum + l.protein);
    final totalFat = logs.fold(0.0, (sum, l) => sum + l.fat);
    final totalCarbs = logs.fold(0.0, (sum, l) => sum + l.carbs);
    final goalCalories = 2000.0;

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
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: (totalCalories / goalCalories).clamp(0, 1),
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalCalories > goalCalories
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
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
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NutrientColumn(
                  label: 'Белки',
                  value: totalProtein,
                  color: Colors.blue,
                ),
                _NutrientColumn(
                  label: 'Жиры',
                  value: totalFat,
                  color: Colors.orange,
                ),
                _NutrientColumn(
                  label: 'Углеводы',
                  value: totalCarbs,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrientColumn extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _NutrientColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)} г',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
