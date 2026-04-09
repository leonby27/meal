import 'dart:io';

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

  Future<void> _edit(BuildContext context) async {
    final db = await AppDatabase.getInstance();
    Product? product;
    if (log.productId != null) {
      product = await db.getProductById(log.productId!);
    }

    if (!context.mounted) return;

    final result = await showDialog<_EditResult>(
      context: context,
      builder: (context) => _EditFoodLogDialog(log: log, product: product),
    );
    if (result == null) return;

    final companion = FoodLogsCompanion(
      grams: drift.Value(result.grams),
      protein: drift.Value(result.protein),
      fat: drift.Value(result.fat),
      carbs: drift.Value(result.carbs),
      calories: drift.Value(result.calories),
      mealType: drift.Value(result.mealType),
      updatedAt: drift.Value(DateTime.now()),
      synced: const drift.Value(false),
    );
    await db.updateFoodLog(log.id, companion);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись обновлена')),
      );
    }
  }

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
                case 'edit':
                  _edit(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, size: 20),
                  title: Text('Редактировать'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
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
    final url = log.imageUrl;
    if (url == null || url.isEmpty) return _placeholderIcon();

    final isLocal = url.startsWith('/');
    if (isLocal) {
      final file = File(url);
      if (!file.existsSync()) return _placeholderIcon();
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholderIcon(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        placeholder: (context, placeholderUrl) => Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        errorWidget: (context, errorUrl, error) => _placeholderIcon(),
      ),
    );
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

class _EditResult {
  final double grams;
  final double protein;
  final double fat;
  final double carbs;
  final double calories;
  final String mealType;

  const _EditResult({
    required this.grams,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.mealType,
  });
}

class _EditFoodLogDialog extends StatefulWidget {
  final FoodLog log;
  final Product? product;

  const _EditFoodLogDialog({required this.log, this.product});

  @override
  State<_EditFoodLogDialog> createState() => _EditFoodLogDialogState();
}

class _EditFoodLogDialogState extends State<_EditFoodLogDialog> {
  late final TextEditingController _gramsController;
  late String _mealType;

  double _proteinPer100g = 0;
  double _fatPer100g = 0;
  double _carbsPer100g = 0;
  double _caloriesPer100g = 0;

  static const _mealTypes = {
    'breakfast': 'Завтрак',
    'lunch': 'Обед',
    'dinner': 'Ужин',
    'snack': 'Перекус',
  };

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(
      text: widget.log.grams.toInt().toString(),
    );
    _mealType = widget.log.mealType;

    final p = widget.product;
    if (p != null &&
        p.proteinPer100g != null &&
        p.fatPer100g != null &&
        p.carbsPer100g != null &&
        p.caloriesPer100g != null) {
      _proteinPer100g = p.proteinPer100g!;
      _fatPer100g = p.fatPer100g!;
      _carbsPer100g = p.carbsPer100g!;
      _caloriesPer100g = p.caloriesPer100g!;
    } else if (widget.log.grams > 0) {
      final g = widget.log.grams;
      _proteinPer100g = widget.log.protein / g * 100;
      _fatPer100g = widget.log.fat / g * 100;
      _carbsPer100g = widget.log.carbs / g * 100;
      _caloriesPer100g = widget.log.calories / g * 100;
    }
  }

  double get _grams => double.tryParse(_gramsController.text) ?? 0;

  double get _protein => _proteinPer100g * _grams / 100;
  double get _fat => _fatPer100g * _grams / 100;
  double get _carbs => _carbsPer100g * _grams / 100;
  double get _calories => _caloriesPer100g * _grams / 100;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.log.productName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'На 100 г: ${_caloriesPer100g.toInt()} ккал  '
            'Б${_proteinPer100g.toStringAsFixed(1)} '
            'Ж${_fatPer100g.toStringAsFixed(1)} '
            'У${_carbsPer100g.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gramsController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Граммы',
              suffixText: 'г',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            '${_calories.toInt()} ккал  •  '
            'Б ${_protein.toStringAsFixed(1)}  '
            'Ж ${_fat.toStringAsFixed(1)}  '
            'У ${_carbs.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _mealType,
            decoration: const InputDecoration(
              labelText: 'Приём пищи',
              isDense: true,
            ),
            items: _mealTypes.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _mealType = v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _grams > 0
              ? () => Navigator.pop(
                    context,
                    _EditResult(
                      grams: _grams,
                      protein: _protein,
                      fat: _fat,
                      carbs: _carbs,
                      calories: _calories,
                      mealType: _mealType,
                    ),
                  )
              : null,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }
}
