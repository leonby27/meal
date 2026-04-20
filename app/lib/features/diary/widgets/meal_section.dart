import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/camera/widgets/ai_meal_result_sheet.dart';

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

  static Widget buildSingleCard({
    required BuildContext context,
    required FoodLog log,
    required String mealType,
    required String dateStr,
    required Future<void> Function(String id) onDelete,
    required Color back2,
  }) {
    return _FoodLogCard(
      log: log,
      mealType: mealType,
      dateStr: dateStr,
      onDelete: () => onDelete(log.id),
      back2: back2,
    );
  }

  Future<void> _copyMeal(BuildContext context) async {
    final targetDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: Localizations.localeOf(context),
      helpText: context.l10n.copyMealTo(title),
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
        SnackBar(content: Text(context.l10n.copiedRecords(count, DateFormat('d MMM', Localizations.localeOf(context).languageCode).format(targetDate)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final totalCalories = logs.fold(0.0, (sum, l) => sum + l.calories);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(icon, size: 24, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 24 / 18,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (totalCalories > 0)
                  Text(
                    context.l10n.kcalValueInt(totalCalories.toInt()),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 24 / 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lineBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: logs.map((log) => _FoodLogTile(
                log: log,
                mealType: mealType,
                dateStr: dateStr,
                onDelete: () => onDelete(log.id),
              )).toList(),
            ),
          ),
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

  Future<void> _toggleFavorite(BuildContext context) async {
    if (log.productId == null) return;
    final db = await AppDatabase.getInstance();
    await db.toggleFavorite(log.productId!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.favoriteUpdated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => AiMealResultSheet.showForDuplicate(context, log: log, dateStr: dateStr),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildPhoto(),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              context.l10n.gramsValue(log.grams.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 18 / 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.kcalValueInt(log.calories.toInt()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 18 / 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                minimumSize: WidgetStatePropertyAll(Size.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              position: PopupMenuPosition.under,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
              ),
              onSelected: (action) {
                switch (action) {
                  case 'delete':
                    onDelete();
                  case 'favorite':
                    _toggleFavorite(context);
                  case 'edit':
                    AiMealResultSheet.showForLog(context, log: log, dateStr: dateStr);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit, size: 20),
                    title: Text(context.l10n.edit),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (log.productId != null)
                  PopupMenuItem(
                    value: 'favorite',
                    child: ListTile(
                      leading: const Icon(Icons.favorite_border, size: 20),
                      title: Text(context.l10n.addToFavorite),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete, size: 20, color: Colors.red),
                    title: Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _placeholderIcon(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (context, placeholderUrl) => Container(
          width: 40, height: 40,
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, color: Colors.grey.shade400, size: 22),
    );
  }
}

class _FoodLogCard extends StatelessWidget {
  final FoodLog log;
  final String mealType;
  final String dateStr;
  final VoidCallback onDelete;
  final Color back2;

  const _FoodLogCard({
    required this.log,
    required this.mealType,
    required this.dateStr,
    required this.onDelete,
    required this.back2,
  });

  Future<void> _toggleFavorite(BuildContext context) async {
    if (log.productId == null) return;
    final db = await AppDatabase.getInstance();
    await db.toggleFavorite(log.productId!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.favoriteUpdated)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryDark = isDark
        ? const Color(0xFF9CA0B2)
        : const Color(0xFF676E85);

    final lineBorder = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: back2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineBorder, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AiMealResultSheet.showForDuplicate(context, log: log, dateStr: dateStr),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildPhoto(cs),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 20 / 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          context.l10n.kcalValueInt(log.calories.toInt()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 18 / 14,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.gramsValue(log.grams.toInt()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 18 / 14,
                            color: secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                position: PopupMenuPosition.under,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.more_vert,
                      size: 20, color: cs.onSurfaceVariant),
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'delete':
                      onDelete();
                    case 'favorite':
                      _toggleFavorite(context);
                    case 'edit':
                      AiMealResultSheet.showForLog(context, log: log, dateStr: dateStr);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit, size: 20),
                      title: Text(context.l10n.edit),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (log.productId != null)
                    PopupMenuItem(
                      value: 'favorite',
                      child: ListTile(
                        leading: const Icon(Icons.favorite_border, size: 20),
                        title: Text(context.l10n.addToFavorite),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading:
                          const Icon(Icons.delete, size: 20, color: Colors.red),
                      title: Text(context.l10n.delete,
                          style: const TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(ColorScheme cs) {
    final url = log.imageUrl;
    if (url == null || url.isEmpty) return _placeholderIcon(cs);

    final isLocal = url.startsWith('/');
    if (isLocal) {
      final file = File(url);
      if (!file.existsSync()) return _placeholderIcon(cs);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(file,
            width: 40, height: 40, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholderIcon(cs)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _placeholderIcon(cs),
      ),
    );
  }

  Widget _placeholderIcon(ColorScheme cs) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, size: 20, color: cs.onSurfaceVariant),
    );
  }
}

