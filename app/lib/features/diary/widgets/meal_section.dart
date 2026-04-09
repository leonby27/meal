import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/core/database/app_database.dart';

class MealSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String mealType;
  final List<FoodLog> logs;
  final String dateStr;
  final Future<void> Function(String id) onDelete;

  const MealSection({
    super.key,
    required this.title,
    required this.icon,
    required this.mealType,
    required this.logs,
    required this.dateStr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalCalories = logs.fold(0.0, (sum, l) => sum + l.calories);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (totalCalories > 0)
                  Text(
                    '${totalCalories.toInt()} ккал',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    context.push('/search?meal_type=$mealType&date=$dateStr');
                  },
                ),
              ],
            ),
          ),
          if (logs.isNotEmpty) ...[
            const Divider(height: 1),
            ...logs.map((log) => _FoodLogTile(
              log: log,
              onDelete: () => onDelete(log.id),
            )),
          ],
        ],
      ),
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final VoidCallback onDelete;

  const _FoodLogTile({required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        dense: true,
        title: Text(
          log.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${log.grams.toInt()} г  •  Б ${log.protein.toStringAsFixed(1)}  '
          'Ж ${log.fat.toStringAsFixed(1)}  У ${log.carbs.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${log.calories.toInt()} ккал',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
