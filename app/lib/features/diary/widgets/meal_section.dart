import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> _copyMeal(BuildContext context) async {
    final targetDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ru'),
      helpText: 'Скопировать $title в…',
    );
    if (targetDate == null || !context.mounted) return;

    final db = await AppDatabase.getInstance();
    final sourceDate = DateFormat('yyyy-MM-dd').parse(dateStr);
    final count = await db.copyMealLogs(
      fromDate: sourceDate,
      toDate: targetDate,
      mealType: mealType,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Скопировано $count записей в ${DateFormat('d MMM', 'ru').format(targetDate)}')),
      );
    }
  }

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
                if (logs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Копировать $title',
                    onPressed: () => _copyMeal(context),
                  ),
              ],
            ),
          ),
          if (logs.isNotEmpty) ...[
            const Divider(height: 1),
            ...logs.map((log) => _FoodLogTile(
              log: log,
              mealType: mealType,
              dateStr: dateStr,
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
  final String mealType;
  final String dateStr;
  final VoidCallback onDelete;

  const _FoodLogTile({
    required this.log,
    required this.mealType,
    required this.dateStr,
    required this.onDelete,
  });

  Future<void> _duplicate(BuildContext context) async {
    final db = await AppDatabase.getInstance();
    await db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(log.productId),
      productName: log.productName,
      mealType: log.mealType,
      mealDate: log.mealDate,
      grams: log.grams,
      protein: drift.Value(log.protein),
      fat: drift.Value(log.fat),
      carbs: drift.Value(log.carbs),
      calories: drift.Value(log.calories),
      imageUrl: drift.Value(log.imageUrl),
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись продублирована')),
      );
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    if (log.productId == null) return;
    final db = await AppDatabase.getInstance();
    await db.toggleFavorite(log.productId!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Избранное обновлено')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildPhoto(),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${log.calories.toInt()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) {
              switch (action) {
                case 'delete':
                  onDelete();
                case 'duplicate':
                  _duplicate(context);
                case 'favorite':
                  _toggleFavorite(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy, size: 20),
                  title: Text('Дублировать'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (log.productId != null)
                const PopupMenuItem(
                  value: 'favorite',
                  child: ListTile(
                    leading: Icon(Icons.favorite_border, size: 20),
                    title: Text('В избранное'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, size: 20, color: Colors.red),
                  title: Text('Удалить', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    if (log.imageUrl != null && log.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: log.imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          errorWidget: (context, url, error) => _placeholderIcon(),
        ),
      );
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 22),
    );
  }
}
