import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/meal_type_helper.dart';

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


  Future<void> _addAgain(BuildContext context) async {
    final result = await showModalBottomSheet<(String, double)?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddAgainSheet(log: log),
    );
    if (result == null) return;

    final (mealType, grams) = result;
    final factor = log.grams > 0 ? grams / log.grams : 1.0;
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day, 12);

    final db = await AppDatabase.getInstance();
    await db.addFoodLog(FoodLogsCompanion.insert(
      id: const Uuid().v4(),
      productId: drift.Value(log.productId),
      productName: log.productName,
      mealType: mealType,
      mealDate: date,
      grams: grams,
      protein: drift.Value(log.protein * factor),
      fat: drift.Value(log.fat * factor),
      carbs: drift.Value(log.carbs * factor),
      calories: drift.Value(log.calories * factor),
      imageUrl: drift.Value(log.imageUrl),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${log.productName} добавлен')),
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
      onTap: () => _addAgain(context),
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
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
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
  late final TextEditingController _gramsCtl;
  late final TextEditingController _proteinCtl;
  late final TextEditingController _fatCtl;
  late final TextEditingController _carbsCtl;
  late final TextEditingController _caloriesCtl;
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
    final log = widget.log;

    _gramsCtl = TextEditingController(text: _fmt(log.grams));
    _proteinCtl = TextEditingController(text: _fmt(log.protein));
    _fatCtl = TextEditingController(text: _fmt(log.fat));
    _carbsCtl = TextEditingController(text: _fmt(log.carbs));
    _caloriesCtl = TextEditingController(text: _fmt(log.calories));
    _mealType = log.mealType;

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
    } else if (log.grams > 0) {
      _proteinPer100g = log.protein / log.grams * 100;
      _fatPer100g = log.fat / log.grams * 100;
      _carbsPer100g = log.carbs / log.grams * 100;
      _caloriesPer100g = log.calories / log.grams * 100;
    }
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  void _recalcFrom(TextEditingController source) {
    if (source == _gramsCtl) {
      // Граммы → масштабировать всё по значениям на 100г
      final g = double.tryParse(_gramsCtl.text) ?? 0;
      final f = g / 100;
      _proteinCtl.text = _fmt(_proteinPer100g * f);
      _fatCtl.text = _fmt(_fatPer100g * f);
      _carbsCtl.text = _fmt(_carbsPer100g * f);
      _caloriesCtl.text = _fmt(_caloriesPer100g * f);
    } else if (source == _proteinCtl || source == _fatCtl || source == _carbsCtl) {
      // Б/Ж/У → пересчитать только калории: К = Б×4 + Ж×9 + У×4
      final p = double.tryParse(_proteinCtl.text) ?? 0;
      final f = double.tryParse(_fatCtl.text) ?? 0;
      final c = double.tryParse(_carbsCtl.text) ?? 0;
      _caloriesCtl.text = _fmt(p * 4 + f * 9 + c * 4);
    } else {
      // Калории → масштабировать граммы, Б, Ж, У пропорционально
      final currentCal = _val(_caloriesCtl);
      final oldCal = _val(_proteinCtl) * 4 + _val(_fatCtl) * 9 + _val(_carbsCtl) * 4;
      if (oldCal <= 0) { setState(() {}); return; }
      final factor = currentCal / oldCal;
      _gramsCtl.text = _fmt(_val(_gramsCtl) * factor);
      _proteinCtl.text = _fmt(_val(_proteinCtl) * factor);
      _fatCtl.text = _fmt(_val(_fatCtl) * factor);
      _carbsCtl.text = _fmt(_val(_carbsCtl) * factor);
    }
    setState(() {});
  }

  double _val(TextEditingController c) => double.tryParse(c.text) ?? 0;

  bool get _valid => _val(_gramsCtl) > 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.log.productName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
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
              controller: _gramsCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Граммы',
                suffixText: 'г',
              ),
              onChanged: (_) => _recalcFrom(_gramsCtl),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Белки'),
                    onChanged: (_) => _recalcFrom(_proteinCtl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Жиры'),
                    onChanged: (_) => _recalcFrom(_fatCtl),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Углев.'),
                    onChanged: (_) => _recalcFrom(_carbsCtl),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Калории', suffixText: 'ккал'),
              onChanged: (_) => _recalcFrom(_caloriesCtl),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(
                    context,
                    _EditResult(
                      grams: _val(_gramsCtl),
                      protein: _val(_proteinCtl),
                      fat: _val(_fatCtl),
                      carbs: _val(_carbsCtl),
                      calories: _val(_caloriesCtl),
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
    _gramsCtl.dispose();
    _proteinCtl.dispose();
    _fatCtl.dispose();
    _carbsCtl.dispose();
    _caloriesCtl.dispose();
    super.dispose();
  }
}

class _AddAgainSheet extends StatefulWidget {
  final FoodLog log;
  const _AddAgainSheet({required this.log});

  @override
  State<_AddAgainSheet> createState() => _AddAgainSheetState();
}

class _AddAgainSheetState extends State<_AddAgainSheet> {
  late String _mealType;
  late final TextEditingController _gramsCtl;

  static const _meals = [
    (key: 'breakfast', label: 'Завтрак', icon: Icons.wb_sunny_outlined),
    (key: 'lunch', label: 'Обед', icon: Icons.wb_cloudy_outlined),
    (key: 'dinner', label: 'Ужин', icon: Icons.nights_stay_outlined),
    (key: 'snack', label: 'Перекус', icon: Icons.cookie_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _mealType = defaultMealType();
    _gramsCtl = TextEditingController(
      text: widget.log.grams.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _gramsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final calPer100 = log.grams > 0 ? (log.calories / log.grams * 100) : 0.0;
    final pPer100 = log.grams > 0 ? (log.protein / log.grams * 100) : 0.0;
    final fPer100 = log.grams > 0 ? (log.fat / log.grams * 100) : 0.0;
    final cPer100 = log.grams > 0 ? (log.carbs / log.grams * 100) : 0.0;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              log.productName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'На 100 г: ${calPer100.toInt()} ккал  '
              'Б${pPer100.toStringAsFixed(1)} '
              'Ж${fPer100.toStringAsFixed(1)} '
              'У${cPer100.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Приём пищи',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _meals.map((m) {
                return ChoiceChip(
                  avatar: Icon(m.icon, size: 18),
                  label: Text(m.label),
                  selected: _mealType == m.key,
                  onSelected: (_) => setState(() => _mealType = m.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gramsCtl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Граммы',
                suffixText: 'г',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final grams = double.tryParse(_gramsCtl.text);
                  if (grams == null || grams <= 0) return;
                  Navigator.pop(context, (_mealType, grams));
                },
                child: const Text('Добавить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
