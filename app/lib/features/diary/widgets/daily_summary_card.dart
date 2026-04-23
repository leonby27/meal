import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class DailySummaryCard extends StatefulWidget {
  final List<FoodLog> logs;
  final DateTime selectedDate;

  const DailySummaryCard({
    super.key,
    required this.logs,
    required this.selectedDate,
  });

  @override
  State<DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard> {
  double _goalCalories = 2000;
  double _goalProtein = 100;
  double _goalFat = 70;
  double _goalCarbs = 250;
  bool _expanded = false;

  bool _showProtein = true;
  bool _showFat = true;
  bool _showCarbs = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = await AppDatabase.getInstance();
    final cal = await db.getSetting('calorie_goal');
    final prot = await db.getSetting('protein_goal');
    final fat = await db.getSetting('fat_goal');
    final carbs = await db.getSetting('carbs_goal');
    final showP = await db.getSetting('show_protein');
    final showF = await db.getSetting('show_fat');
    final showC = await db.getSetting('show_carbs');
    if (mounted) {
      setState(() {
        _goalCalories = double.tryParse(cal ?? '') ?? 2000;
        _goalProtein = double.tryParse(prot ?? '') ?? 100;
        _goalFat = double.tryParse(fat ?? '') ?? 70;
        _goalCarbs = double.tryParse(carbs ?? '') ?? 250;
        _showProtein = showP != 'false';
        _showFat = showF != 'false';
        _showCarbs = showC != 'false';
      });
    }
  }

  String _formatNumber(double value) {
    final intVal = value.toInt();
    if (intVal >= 1000) {
      final str = intVal.toString();
      final buffer = StringBuffer();
      for (var i = 0; i < str.length; i++) {
        if (i > 0 && (str.length - i) % 3 == 0) buffer.write('\u{00A0}');
        buffer.write(str[i]);
      }
      return buffer.toString();
    }
    return intVal.toString();
  }

  bool get _hasVisibleMacros => _showProtein || _showFat || _showCarbs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final back2 = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final trackColor = isDark ? AppColors.lineDT100 : cs.outlineVariant;
    final secondaryTextColor = cs.onSurfaceVariant;
    final primaryTextColor = cs.onSurface;

    final totalCalories =
        widget.logs.fold(0.0, (sum, l) => sum + l.calories);
    final totalProtein =
        widget.logs.fold(0.0, (sum, l) => sum + l.protein);
    final totalFat = widget.logs.fold(0.0, (sum, l) => sum + l.fat);
    final totalCarbs =
        widget.logs.fold(0.0, (sum, l) => sum + l.carbs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: back2,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MacroRow(
              iconAsset: 'assets/icons/cal.svg',
              current: totalCalories,
              goal: _goalCalories,
              currentLabel: context.l10n.kcalValue(_formatNumber(totalCalories)),
              goalLabel: context.l10n.kcalValue(_formatNumber(_goalCalories)),
              gradient: const LinearGradient(
                colors: [Color(0xFF22D33A), Color(0xFF1EBF92)],
              ),
              trackColor: trackColor,
              labelColor: secondaryTextColor,
              valueLabelColor: primaryTextColor,
              cardColor: back2,
            ),

            if (_hasVisibleMacros) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        children: [
                          if (_showProtein) ...[
                            const SizedBox(height: 20),
                            _MacroRow(
                              iconAsset: 'assets/icons/belok.svg',
                              current: totalProtein,
                              goal: _goalProtein,
                              currentLabel: '${totalProtein.toInt()} ${context.l10n.proteinShort}',
                              goalLabel: context.l10n.proteinGoalLabel(_goalProtein.toInt()),
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFFF0681B),
                                  Color(0xFFD91D1D)
                                ],
                              ),
                              trackColor: trackColor,
                              labelColor: secondaryTextColor,
                              valueLabelColor: primaryTextColor,
                              cardColor: back2,
                            ),
                          ],
                          if (_showFat) ...[
                            const SizedBox(height: 20),
                            _MacroRow(
                              iconAsset: 'assets/icons/fat.svg',
                              current: totalFat,
                              goal: _goalFat,
                              currentLabel: '${totalFat.toInt()} ${context.l10n.fatShort}',
                              goalLabel: context.l10n.fatGoalLabel(_goalFat.toInt()),
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFFFFBB00),
                                  Color(0xFFD0FF00)
                                ],
                              ),
                              trackColor: trackColor,
                              labelColor: secondaryTextColor,
                              valueLabelColor: primaryTextColor,
                              cardColor: back2,
                            ),
                          ],
                          if (_showCarbs) ...[
                            const SizedBox(height: 20),
                            _MacroRow(
                              iconAsset: 'assets/icons/uglevod.svg',
                              current: totalCarbs,
                              goal: _goalCarbs,
                              currentLabel: '${totalCarbs.toInt()} ${context.l10n.carbsShort}',
                              goalLabel: context.l10n.carbsGoalLabel(_goalCarbs.toInt()),
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFF1787D1),
                                  Color(0xFF17D1C7)
                                ],
                              ),
                              trackColor: trackColor,
                              labelColor: secondaryTextColor,
                              valueLabelColor: primaryTextColor,
                              cardColor: back2,
                            ),
                          ],
                        ],
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? context.l10n.showLess : context.l10n.showMore,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 20 / 15,
                            color: _expanded
                                ? secondaryTextColor
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: _expanded
                                ? secondaryTextColor
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openCustomizeSheet(context),
                    child: SvgPicture.asset(
                      'assets/icons/settings_adjust.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        secondaryTextColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!_hasVisibleMacros) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _openCustomizeSheet(context),
                  child: SvgPicture.asset(
                    'assets/icons/settings_adjust.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      secondaryTextColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomizeSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_CustomizeResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xCC000000),
      builder: (ctx) => _CustomizeViewSheet(
        showProtein: _showProtein,
        showFat: _showFat,
        showCarbs: _showCarbs,
      ),
    );
    if (result == null) return;

    final db = await AppDatabase.getInstance();
    await db.setSetting('show_protein', result.showProtein.toString());
    await db.setSetting('show_fat', result.showFat.toString());
    await db.setSetting('show_carbs', result.showCarbs.toString());

    if (mounted) {
      setState(() {
        _showProtein = result.showProtein;
        _showFat = result.showFat;
        _showCarbs = result.showCarbs;
      });
    }
  }
}

class _CustomizeResult {
  final bool showProtein;
  final bool showFat;
  final bool showCarbs;

  const _CustomizeResult({
    required this.showProtein,
    required this.showFat,
    required this.showCarbs,
  });
}

class _CustomizeViewSheet extends StatefulWidget {
  final bool showProtein;
  final bool showFat;
  final bool showCarbs;

  const _CustomizeViewSheet({
    required this.showProtein,
    required this.showFat,
    required this.showCarbs,
  });

  @override
  State<_CustomizeViewSheet> createState() => _CustomizeViewSheetState();
}

class _CustomizeViewSheetState extends State<_CustomizeViewSheet> {
  late bool _showProtein;
  late bool _showFat;
  late bool _showCarbs;

  @override
  void initState() {
    super.initState();
    _showProtein = widget.showProtein;
    _showFat = widget.showFat;
    _showCarbs = widget.showCarbs;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final blockBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final cs = Theme.of(context).colorScheme;
    final closeBtnBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final secondaryDark = isDark
        ? const Color(0xFF9CA0B2)
        : const Color(0xFF676E85);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.customizeView,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 24 / 18,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(
                          context,
                          _CustomizeResult(
                            showProtein: _showProtein,
                            showFat: _showFat,
                            showCarbs: _showCarbs,
                          ),
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: closeBtnBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary metric section
                    Text(
                      context.l10n.primaryMetric,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        color: secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: blockBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _MetricRow(
                        iconAsset: 'assets/icons/cal.svg',
                        label: context.l10n.caloriesLabel,
                        primaryColor: cs.onSurface,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Other metrics section
                    Text(
                      context.l10n.otherMetrics,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        color: secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: blockBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _ToggleMetricRow(
                        iconAsset: 'assets/icons/belok.svg',
                        label: context.l10n.proteinLabel,
                        value: _showProtein,
                        primaryColor: cs.onSurface,
                        onChanged: (v) => setState(() => _showProtein = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: blockBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _ToggleMetricRow(
                        iconAsset: 'assets/icons/fat.svg',
                        label: context.l10n.fatLabel,
                        value: _showFat,
                        primaryColor: cs.onSurface,
                        onChanged: (v) => setState(() => _showFat = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: blockBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _ToggleMetricRow(
                        iconAsset: 'assets/icons/uglevod.svg',
                        label: context.l10n.carbsLabel,
                        value: _showCarbs,
                        primaryColor: cs.onSurface,
                        onChanged: (v) => setState(() => _showCarbs = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final Color primaryColor;

  const _MetricRow({
    required this.iconAsset,
    required this.label,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: SvgPicture.asset(iconAsset, width: 28, height: 28),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 20 / 15,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleMetricRow extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool value;
  final Color primaryColor;
  final ValueChanged<bool> onChanged;

  const _ToggleMetricRow({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: SvgPicture.asset(iconAsset, width: 28, height: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 20 / 15,
                color: primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 24,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch.adaptive(
                value: value,
                // activeColor maps to thumb on Android; without an explicit track
                // color the framework falls back to thumbColor at 50% alpha — pale track.
                activeTrackColor: AppColors.primary,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Theme.of(context).colorScheme.outline;
                }),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String iconAsset;
  final double current;
  final double goal;
  final String currentLabel;
  final String goalLabel;
  final LinearGradient gradient;
  final Color trackColor;
  final Color labelColor;
  final Color valueLabelColor;
  final Color cardColor;

  const _MacroRow({
    required this.iconAsset,
    required this.current,
    required this.goal,
    required this.currentLabel,
    required this.goalLabel,
    required this.gradient,
    required this.trackColor,
    required this.labelColor,
    required this.valueLabelColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: SvgPicture.asset(iconAsset, width: 28, height: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GradientProgressBar(
            current: current,
            goal: goal,
            barHeight: 12,
            markerHeight: 16,
            borderRadius: 4,
            gradient: gradient,
            currentLabel: currentLabel,
            goalLabel: goalLabel,
            trackColor: trackColor,
            labelColor: labelColor,
            valueLabelColor: valueLabelColor,
            cardColor: cardColor,
          ),
        ),
      ],
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double current;
  final double goal;
  final double barHeight;
  final double markerHeight;
  final double borderRadius;
  final LinearGradient gradient;
  final String currentLabel;
  final String goalLabel;
  final Color trackColor;
  final Color labelColor;
  final Color valueLabelColor;
  final Color cardColor;

  const _GradientProgressBar({
    required this.current,
    required this.goal,
    required this.barHeight,
    required this.markerHeight,
    required this.borderRadius,
    required this.gradient,
    required this.currentLabel,
    required this.goalLabel,
    required this.trackColor,
    required this.labelColor,
    required this.valueLabelColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        SizedBox(
          height: markerHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final fillWidth = totalWidth * progress;
              final markerPos = totalWidth * progress;
              final barTop = (markerHeight - barHeight) / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: barTop,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                  ),
                  if (progress > 0)
                    Positioned(
                      left: 0,
                      top: barTop,
                      child: Container(
                        width: fillWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            bottomLeft: Radius.circular(borderRadius),
                            topRight: progress >= 1.0
                                ? Radius.circular(borderRadius)
                                : Radius.zero,
                            bottomRight: progress >= 1.0
                                ? Radius.circular(borderRadius)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                  if (progress > 0 && progress < 1.0)
                    Positioned(
                      left: markerPos - 1,
                      top: 0,
                      child: Container(
                        width: 2,
                        height: markerHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final markerX = totalWidth * progress;

            return SizedBox(
              height: 18,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Text(
                      '0',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        color: labelColor,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Text(
                      goalLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 18 / 14,
                        color: labelColor,
                      ),
                    ),
                  ),
                  _PositionedValueLabel(
                    markerX: markerX,
                    totalWidth: totalWidth,
                    label: currentLabel,
                    color: valueLabelColor,
                    backgroundColor: cardColor,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PositionedValueLabel extends StatelessWidget {
  final double markerX;
  final double totalWidth;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _PositionedValueLabel({
    required this.markerX,
    required this.totalWidth,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 18 / 14,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const pad = 4.0;
    final labelWidth = textPainter.width + pad * 2;
    final halfLabel = labelWidth / 2;

    double left = markerX - halfLabel;
    if (left < 0) left = 0;
    if (left + labelWidth > totalWidth) left = totalWidth - labelWidth;

    return Positioned(
      left: left,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: pad),
        color: backgroundColor,
        child: Text(
          label,
          style: textStyle.copyWith(color: color),
        ),
      ),
    );
  }
}
