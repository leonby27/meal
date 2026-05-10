import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (mounted) {
      setState(() {
        _goalCalories = double.tryParse(cal ?? '') ?? 2000;
        _goalProtein = double.tryParse(prot ?? '') ?? 100;
        _goalFat = double.tryParse(fat ?? '') ?? 70;
        _goalCarbs = double.tryParse(carbs ?? '') ?? 250;
      });
    }
  }

  String _formatNumber(num value) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor =
        isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final secondary = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final primary = cs.onSurface;
    final pillSurface =
        isDark ? AppColors.darkSurface2 : AppColors.lightScaffold;
    final primaryLight = isDark
        ? AppColors.darkPrimaryLight
        : AppColors.lightPrimaryLight;

    final totalCalories =
        widget.logs.fold(0.0, (sum, l) => sum + l.calories);
    final totalProtein =
        widget.logs.fold(0.0, (sum, l) => sum + l.protein);
    final totalFat = widget.logs.fold(0.0, (sum, l) => sum + l.fat);
    final totalCarbs =
        widget.logs.fold(0.0, (sum, l) => sum + l.carbs);

    final remaining = math.max(0, (_goalCalories - totalCalories).round());
    final caloriesProgress = _goalCalories > 0
        ? (totalCalories / _goalCalories).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: AppTheme.cardEdgeBorder(isDark: isDark),
          boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 22),
                _GaugeSection(
                  remaining: remaining,
                  progress: caloriesProgress,
                  eaten: totalCalories,
                  goal: _goalCalories,
                  remainingLabel: l10n.caloriesRemaining,
                  eatenLabel: l10n.dailyEatenLabel,
                  goalLabel: l10n.dailyGoalLabel,
                  primary: primary,
                  secondary: secondary,
                  lineColor: lineColor,
                  formatNumber: _formatNumber,
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _MacrosRow(
                    protein: totalProtein,
                    carbs: totalCarbs,
                    fat: totalFat,
                    goalProtein: _goalProtein,
                    goalCarbs: _goalCarbs,
                    goalFat: _goalFat,
                    trackColor: lineColor,
                    primary: primary,
                    secondary: secondary,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => context.push('/stats'),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: pillSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/stats.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        primaryLight,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugeSection extends StatelessWidget {
  const _GaugeSection({
    required this.remaining,
    required this.progress,
    required this.eaten,
    required this.goal,
    required this.remainingLabel,
    required this.eatenLabel,
    required this.goalLabel,
    required this.primary,
    required this.secondary,
    required this.lineColor,
    required this.formatNumber,
  });

  final int remaining;
  final double progress;
  final double eaten;
  final double goal;
  final String remainingLabel;
  final String eatenLabel;
  final String goalLabel;
  final Color primary;
  final Color secondary;
  final Color lineColor;
  final String Function(num) formatNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 41),
            child: _SidePill(
              value: formatNumber(eaten),
              label: eatenLabel,
              primary: primary,
              secondary: secondary,
              lineColor: lineColor,
            ),
          ),
          _SemicircleGauge(
            remaining: remaining,
            progress: progress,
            remainingLabel: remainingLabel,
            primary: primary,
            secondary: secondary,
            trackColor: lineColor,
            formatNumber: formatNumber,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 41),
            child: _SidePill(
              value: formatNumber(goal),
              label: goalLabel,
              primary: primary,
              secondary: secondary,
              lineColor: lineColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePill extends StatelessWidget {
  const _SidePill({
    required this.value,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.lineColor,
  });

  final String value;
  final String label;
  final Color primary;
  final Color secondary;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 22,
          constraints: const BoxConstraints(minWidth: 56),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: lineColor, width: 1),
            borderRadius: BorderRadius.circular(41),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.momoTrustDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 16 / 13,
                color: primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 16 / 13,
            color: secondary,
          ),
        ),
      ],
    );
  }
}

class _SemicircleGauge extends StatelessWidget {
  const _SemicircleGauge({
    required this.remaining,
    required this.progress,
    required this.remainingLabel,
    required this.primary,
    required this.secondary,
    required this.trackColor,
    required this.formatNumber,
  });

  final int remaining;
  final double progress;
  final String remainingLabel;
  final Color primary;
  final Color secondary;
  final Color trackColor;
  final String Function(num) formatNumber;

  static const double _width = 186;
  static const double _height = 93;
  static const double _stroke = 8;
  static const double _padX = 8;
  static const double _padTop = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GaugePainter(
                progress: progress,
                trackColor: trackColor,
                strokeWidth: _stroke,
                padX: _padX,
                padTop: _padTop,
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/cal.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
          Positioned(
            top: 39,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                formatNumber(remaining),
                style: GoogleFonts.momoTrustDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  height: 28 / 24,
                  color: primary,
                ),
              ),
            ),
          ),
          Positioned(
            top: 71,
            left: 8,
            right: 8,
            child: Center(
              child: Text(
                remainingLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 16 / 13,
                  color: secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.strokeWidth,
    required this.padX,
    required this.padTop,
  });

  final double progress;
  final Color trackColor;
  final double strokeWidth;
  final double padX;
  final double padTop;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - 2 * padX) / 2;
    final cx = size.width / 2;
    final cy = padTop + radius;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    if (progress <= 0) return;

    final valuePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topCenter,
        colors: [Color(0xFF22D33A), Color(0xFF1EBF92)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi * progress, false, valuePaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

class _MacrosRow extends StatelessWidget {
  const _MacrosRow({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.goalProtein,
    required this.goalCarbs,
    required this.goalFat,
    required this.trackColor,
    required this.primary,
    required this.secondary,
  });

  final double protein;
  final double carbs;
  final double fat;
  final double goalProtein;
  final double goalCarbs;
  final double goalFat;
  final Color trackColor;
  final Color primary;
  final Color secondary;

  static const _proteinGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Color(0xFFF0681B), Color(0xFFD91D1D)],
  );
  static const _carbsGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Color(0xFFFFBB00), Color(0xFFD0FF00)],
  );
  static const _fatGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Color(0xFF1787D1), Color(0xFF17D1C7)],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MacroColumn(
            label: l10n.proteinLabel,
            current: protein,
            goal: goalProtein,
            goalSuffix: 'g',
            gradient: _proteinGradient,
            trackColor: trackColor,
            primary: primary,
            secondary: secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroColumn(
            label: l10n.carbsLabel,
            current: carbs,
            goal: goalCarbs,
            goalSuffix: 'g',
            gradient: _carbsGradient,
            trackColor: trackColor,
            primary: primary,
            secondary: secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MacroColumn(
            label: l10n.fatLabel,
            current: fat,
            goal: goalFat,
            goalSuffix: 'g',
            gradient: _fatGradient,
            trackColor: trackColor,
            primary: primary,
            secondary: secondary,
          ),
        ),
      ],
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.label,
    required this.current,
    required this.goal,
    required this.goalSuffix,
    required this.gradient,
    required this.trackColor,
    required this.primary,
    required this.secondary,
  });

  final String label;
  final double current;
  final double goal;
  final String goalSuffix;
  final LinearGradient gradient;
  final Color trackColor;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.momoTrustDisplay(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 16 / 14,
              color: primary,
            ),
            children: [
              TextSpan(text: '${current.toInt()}'),
              TextSpan(
                text: ' / ${goal.toInt()}$goalSuffix',
                style: TextStyle(color: secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 8, color: trackColor),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 16 / 13,
            color: secondary,
          ),
        ),
      ],
    );
  }
}
