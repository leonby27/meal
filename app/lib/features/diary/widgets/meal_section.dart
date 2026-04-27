import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/camera/widgets/ai_meal_result_sheet.dart';

enum FoodLogCardVariant { compact, expanded }

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
    String? duplicateDateStr,
    VoidCallback? onDuplicateAdded,
    required Future<void> Function(String id) onDelete,
    required Color back2,
    FoodLogCardVariant variant = FoodLogCardVariant.expanded,
    double calorieGoal = 0,
  }) {
    return _FoodLogCard(
      log: log,
      mealType: mealType,
      dateStr: dateStr,
      duplicateDateStr: duplicateDateStr,
      onDuplicateAdded: onDuplicateAdded,
      onDelete: () => onDelete(log.id),
      back2: back2,
      variant: variant,
      calorieGoal: calorieGoal,
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
        SnackBar(
          content: Text(
            context.l10n.copiedRecords(
              count,
              DateFormat(
                'd MMM',
                Localizations.localeOf(context).languageCode,
              ).format(targetDate),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                for (var i = 0; i < logs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _FoodLogTile(
                    log: logs[i],
                    mealType: mealType,
                    dateStr: dateStr,
                    onDelete: () => onDelete(logs[i].id),
                  ),
                ],
              ],
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
    final db = await AppDatabase.getInstance();
    if (log.productId != null) {
      await db.toggleFavorite(log.productId!);
    } else {
      final newId = await db.addLogToFavorites(log);
      if (newId == null) return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.favoriteUpdated)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => AiMealResultSheet.showForDuplicate(
        context,
        log: log,
        dateStr: dateStr,
      ),
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
                child: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
              onSelected: (action) {
                switch (action) {
                  case 'delete':
                    onDelete();
                  case 'favorite':
                    _toggleFavorite(context);
                  case 'edit':
                    AiMealResultSheet.showForLog(
                      context,
                      log: log,
                      dateStr: dateStr,
                    );
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
                    leading: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                    title: Text(
                      context.l10n.delete,
                      style: const TextStyle(color: Colors.red),
                    ),
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
          width: 40,
          height: 40,
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
  final String? duplicateDateStr;
  final VoidCallback? onDuplicateAdded;
  final VoidCallback onDelete;
  final Color back2;
  final FoodLogCardVariant variant;
  final double calorieGoal;

  const _FoodLogCard({
    required this.log,
    required this.mealType,
    required this.dateStr,
    this.duplicateDateStr,
    this.onDuplicateAdded,
    required this.onDelete,
    required this.back2,
    required this.variant,
    required this.calorieGoal,
  });

  Future<void> _toggleFavorite(BuildContext context) async {
    final db = await AppDatabase.getInstance();
    if (log.productId != null) {
      await db.toggleFavorite(log.productId!);
    } else {
      final newId = await db.addLogToFavorites(log);
      if (newId == null) return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.favoriteUpdated)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryDark = isDark
        ? const Color(0xFF9CA0B2)
        : const Color(0xFF676E85);

    if (variant == FoodLogCardVariant.expanded) {
      return _buildExpanded(context, cs, secondaryDark);
    }

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: back2,
        borderRadius: BorderRadius.circular(20),
        border: AppTheme.cardEdgeBorder(isDark: isDark),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final saved = await AiMealResultSheet.showForDuplicate(
            context,
            log: log,
            dateStr: duplicateDateStr ?? dateStr,
          );
          if (saved && context.mounted) onDuplicateAdded?.call();
        },
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
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'delete':
                      onDelete();
                    case 'favorite':
                      _toggleFavorite(context);
                    case 'edit':
                      AiMealResultSheet.showForLog(
                        context,
                        log: log,
                        dateStr: dateStr,
                      );
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
                      leading: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      title: Text(
                        context.l10n.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
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

  Widget _buildExpanded(
    BuildContext context,
    ColorScheme cs,
    Color secondaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kcalPercent = calorieGoal > 0
        ? (log.calories / calorieGoal * 100).round().clamp(0, 999)
        : 0;

    return Container(
      height: 155,
      decoration: BoxDecoration(
        color: back2,
        borderRadius: BorderRadius.circular(20),
        border: AppTheme.cardEdgeBorder(isDark: isDark),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final saved = await AiMealResultSheet.showForDuplicate(
            context,
            log: log,
            dateStr: duplicateDateStr ?? dateStr,
          );
          if (saved && context.mounted) onDuplicateAdded?.call();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhoto(cs, size: 80, radius: 16),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                          Text(
                            context.l10n.gramsValue(log.grams.toInt()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 18 / 14,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${context.l10n.kcalValueInt(log.calories.toInt())} · $kcalPercent%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 18 / 14,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildMenuButton(context, cs),
                  ),
                ],
              ),
              const Spacer(),
              _MacroBreakdown(
                log: log,
                calorieGoal: calorieGoal,
                surfaceColor: back2,
                secondaryColor: secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, ColorScheme cs) {
    return PopupMenuButton<String>(
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
            title: Text(
              context.l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoto(ColorScheme cs, {double size = 40, double radius = 8}) {
    final url = log.imageUrl;
    if (url == null || url.isEmpty) {
      return _placeholderIcon(cs, size: size, radius: radius);
    }

    final isLocal = url.startsWith('/');
    if (isLocal) {
      final file = File(url);
      if (!file.existsSync()) {
        return _placeholderIcon(cs, size: size, radius: radius);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _placeholderIcon(cs, size: size, radius: radius),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _placeholderIcon(cs, size: size, radius: radius),
      ),
    );
  }

  Widget _placeholderIcon(
    ColorScheme cs, {
    double size = 40,
    double radius = 8,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.restaurant,
        size: size >= 80 ? 34 : 20,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _MacroBreakdown extends StatelessWidget {
  static const _proteinColor = Color(0xFFF04438);
  static const _fatColor = Color(0xFFE7F900);
  static const _carbsColor = Color(0xFF20BDF2);

  final FoodLog log;
  final double calorieGoal;
  final Color surfaceColor;
  final Color secondaryColor;

  const _MacroBreakdown({
    required this.log,
    required this.calorieGoal,
    required this.surfaceColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final dividerColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final protein = log.protein.clamp(0, double.infinity).toDouble();
    final fat = log.fat.clamp(0, double.infinity).toDouble();
    final carbs = log.carbs.clamp(0, double.infinity).toDouble();
    final proteinCal = protein * 4;
    final fatCal = fat * 9;
    final carbsCal = carbs * 4;
    final maxCal = [proteinCal, fatCal, carbsCal].reduce((a, b) => a > b ? a : b);
    final hasDominant = maxCal > 0;
    final proteinDominant = hasDominant && proteinCal == maxCal;
    final fatDominant =
        hasDominant && !proteinDominant && fatCal == maxCal;
    final carbsDominant =
        hasDominant && !proteinDominant && !fatDominant && carbsCal == maxCal;

    final calorieRatio = calorieGoal > 0
        ? (log.calories / calorieGoal).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Container(
            height: 6,
            color: trackColor,
            child: calorieRatio <= 0
                ? const SizedBox.expand()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: calorieRatio,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF22D33A), Color(0xFF1EBF92)],
                          ),
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _MacroLabel(
                dotColor: _proteinColor,
                label: context.l10n.proteinShort.toUpperCase(),
                grams: protein,
                percent: _targetPercent(protein, calorieGoal * 0.3 / 4),
                textColor: proteinDominant ? cs.onSurface : secondaryColor,
                isDominant: proteinDominant,
              ),
            ),
            _MacroDivider(color: dividerColor),
            Expanded(
              child: _MacroLabel(
                dotColor: _fatColor,
                label: context.l10n.fatShort.toUpperCase(),
                grams: fat,
                percent: _targetPercent(fat, calorieGoal * 0.3 / 9),
                textColor: fatDominant ? cs.onSurface : secondaryColor,
                isDominant: fatDominant,
              ),
            ),
            _MacroDivider(color: dividerColor),
            Expanded(
              child: _MacroLabel(
                dotColor: _carbsColor,
                label: context.l10n.carbsShort.toUpperCase(),
                grams: carbs,
                percent: _targetPercent(carbs, calorieGoal * 0.4 / 4),
                textColor: carbsDominant ? cs.onSurface : secondaryColor,
                isDominant: carbsDominant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _targetPercent(double value, double target) =>
      target > 0 ? (value / target * 100).round().clamp(0, 999) : 0;
}

class _MacroDivider extends StatelessWidget {
  final Color color;

  const _MacroDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 8,
      color: color,
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final Color dotColor;
  final String label;
  final double grams;
  final int percent;
  final Color textColor;
  final bool isDominant;

  const _MacroLabel({
    required this.dotColor,
    required this.label,
    required this.grams,
    required this.percent,
    required this.textColor,
    this.isDominant = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '$label: ${grams.round()} · $percent%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDominant ? FontWeight.w500 : FontWeight.w400,
              height: 16 / 13,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
