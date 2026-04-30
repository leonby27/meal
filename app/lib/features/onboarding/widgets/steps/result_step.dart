import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/models/onboarding_data.dart';

class ResultStep extends StatefulWidget {
  final OnboardingData data;

  const ResultStep({super.key, required this.data});

  @override
  State<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<ResultStep>
    with TickerProviderStateMixin {
  // Conversion factor used to format weights for users on imperial units.
  // The internal data model is always kg; we only convert for display.
  static const double _kgToLb = 2.20462;

  AnimationController? _controller;
  Animation<double>? _animation;
  late final ConfettiController _confettiController;
  bool _disclaimerExpanded = false;

  double get _progress => _animation?.value ?? 0.0;

  @override
  void initState() {
    super.initState();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _controller = ctrl;
    _animation = CurvedAnimation(parent: ctrl, curve: Curves.easeOut);
    ctrl.forward(from: 0.08);

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 600),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// Formats a weight (always stored as kg) for display, respecting the
  /// user's unit system. Imperial uses universal "lb"; metric uses the
  /// localized [kgUnit] string so EN/DE/etc. all read naturally.
  String _formatWeight(double kg) {
    if (widget.data.isImperial) {
      return '${(kg * _kgToLb).round()} lb';
    }
    return '${kg.round()} ${context.l10n.kgUnit}';
  }

  /// Formats a weekly weight-change rate. Trims trailing zeros so that
  /// 0.5 kg renders as "0.5 кг" but 0.25 kg keeps two decimals.
  String _formatPace(double kgPerWeek) {
    if (widget.data.isImperial) {
      return '${(kgPerWeek * _kgToLb).toStringAsFixed(1)} lb';
    }
    var s = kgPerWeek.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return '$s ${context.l10n.kgUnit}';
  }

  String _formattedTargetDate() {
    final date = widget.data.targetDate ?? DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }

  String _formatCalories(int cal) {
    if (cal >= 1000) {
      final whole = cal ~/ 1000;
      final rest = cal % 1000;
      if (rest == 0) return '$whole 000';
      return '$whole ${rest.toString().padLeft(3, '0')}';
    }
    return '$cal';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    final calories = widget.data.calorieGoal?.round() ?? 0;
    final protein = widget.data.proteinGoal?.round() ?? 0;
    final fat = widget.data.fatGoal?.round() ?? 0;
    final carbs = widget.data.carbsGoal?.round() ?? 0;
    final totalGrams = protein + fat + carbs;
    final proteinPct =
        totalGrams > 0 ? ((protein / totalGrams) * 100).round() : 0;
    final fatPct = totalGrams > 0 ? ((fat / totalGrams) * 100).round() : 0;
    final carbsPct = totalGrams > 0 ? ((carbs / totalGrams) * 100).round() : 0;

    final goal = widget.data.goal;
    final isLose = goal == 'lose';
    final isGain = goal == 'gain';
    // Treat any unknown / null goal as "maintain" so we don't show a
    // "today" target date by accident.
    final isMaintain = !isLose && !isGain;

    final delta = (widget.data.weightKg - widget.data.targetWeightKg).abs();

    final subtitle = isLose
        ? context.l10n.resultPlanReadyLose(_formatWeight(delta), calories)
        : isGain
            ? context.l10n.resultPlanReadyGain(_formatWeight(delta), calories)
            : context.l10n.resultPlanReadyMaintain(calories);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // --- Section 1: Title + personalized subtitle ---
              Text(
                context.l10n.resultPlanReadyTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // --- Section 2: Macro ring with animated values ---
              AnimatedBuilder(
                animation: _animation ?? const AlwaysStoppedAnimation(0.0),
                builder: (context, _) {
                  final p = _progress;
                  final animCal = (calories * p).round();
                  final animProtein = (protein * p).round();
                  final animFat = (fat * p).round();
                  final animCarbs = (carbs * p).round();

                  return SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CustomPaint(
                            painter: _MacroRingPainter(
                              proteinFraction: totalGrams > 0
                                  ? protein / totalGrams
                                  : 0.33,
                              fatFraction:
                                  totalGrams > 0 ? fat / totalGrams : 0.33,
                              carbsFraction:
                                  totalGrams > 0 ? carbs / totalGrams : 0.34,
                              progress: p,
                              bgColor: cs.outline.withAlpha(30),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatCalories(animCal),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.kcalPerDay,
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 0,
                          top: 50,
                          child: _MacroLabel(
                            value: '$animProtein ${context.l10n.gramsUnit}',
                            color: AppColors.blue,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 40,
                          child: _MacroLabel(
                            value: '$animFat ${context.l10n.gramsUnit}',
                            color: AppColors.orange,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 20,
                          child: _MacroLabel(
                            value: '$animCarbs ${context.l10n.gramsUnit}',
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- Legend ---
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendItem(
                    label: '${context.l10n.carbsLabel} ($carbsPct%)',
                    color: AppColors.green,
                  ),
                  _LegendItem(
                    label: '${context.l10n.proteinLabel} ($proteinPct%)',
                    color: AppColors.blue,
                  ),
                  _LegendItem(
                    label: '${context.l10n.fatLabel} ($fatPct%)',
                    color: AppColors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Section 3: Trust anchor + adjustability hint ---
              Text(
                context.l10n.resultRingTrustLine,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.resultRingAdjustLine,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // --- Section 4: Goal card (shape depends on goal type) ---
              _GoalCard(
                isMaintain: isMaintain,
                regularTitle: context.l10n.resultGoalCardTitle,
                maintainTitle: isMaintain
                    ? context.l10n.resultGoalMaintainTitle(
                        _formatWeight(widget.data.weightKg),
                      )
                    : null,
                maintainSubtitle: isMaintain
                    ? context.l10n.resultGoalMaintainSubtitle
                    : null,
                fromWeight:
                    isMaintain ? null : _formatWeight(widget.data.weightKg),
                toWeight: isMaintain
                    ? null
                    : _formatWeight(widget.data.targetWeightKg),
                dateLine: isMaintain
                    ? null
                    : context.l10n.resultGoalDateBy(_formattedTargetDate()),
                paceLine: isMaintain
                    ? null
                    : context.l10n.resultGoalPace(
                        _formatPace(isLose ? 0.5 : 0.25),
                      ),
                cardBg: cardBg,
                lineColor: lineColor,
                isDark: isDark,
              ),
              const SizedBox(height: 28),

              // --- Section 5: Personalized "what you'll notice" ---
              Text(
                context.l10n.resultBenefitsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isLose
                    ? context.l10n.resultBenefitsLose
                    : isGain
                        ? context.l10n.resultBenefitsGain
                        : context.l10n.resultBenefitsMaintain,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // --- Section 6: Free vs Premium bridge ---
              _BridgeCard(
                title: context.l10n.resultBridgeTitle,
                freeLine: context.l10n.resultBridgeFreeLine,
                premiumLine: context.l10n.resultBridgePremiumLine,
                cardBg: cardBg,
                lineColor: lineColor,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // --- Section 7: Compact disclaimer with "Learn more" toggle ---
              _ExpandableDisclaimer(
                shortText: context.l10n.resultDisclaimerShort,
                fullText: context.l10n.resultDisclaimer,
                expandLabel: context.l10n.resultDisclaimerExpand,
                expanded: _disclaimerExpanded,
                onToggle: () => setState(
                  () => _disclaimerExpanded = !_disclaimerExpanded,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 40,
              minBlastForce: 15,
              emissionFrequency: 0.4,
              numberOfParticles: 20,
              gravity: 0.12,
              particleDrag: 0.04,
              shouldLoop: false,
              minimumSize: const Size(8, 4),
              maximumSize: const Size(14, 7),
              colors: const [
                AppColors.blue,
                AppColors.green,
                AppColors.orange,
                AppColors.purple,
                Color(0xFFFFD700),
                Color(0xFFFF69B4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3-segment macro ring painter
// ---------------------------------------------------------------------------
class _MacroRingPainter extends CustomPainter {
  final double proteinFraction;
  final double fatFraction;
  final double carbsFraction;
  final double progress;
  final Color bgColor;

  static const _strokeWidth = 22.0;
  static const _gap = 0.04; // radians gap between segments

  _MacroRingPainter({
    required this.proteinFraction,
    required this.fatFraction,
    required this.carbsFraction,
    required this.progress,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final totalAngle = 2 * math.pi * progress;
    final totalGap = _gap * 3;
    final usableAngle = totalAngle - totalGap;
    if (usableAngle <= 0) return;

    final segments = [
      (proteinFraction, AppColors.blue),
      (fatFraction, AppColors.orange),
      (carbsFraction, AppColors.green),
    ];

    var startAngle = -math.pi / 2;
    for (final (fraction, color) in segments) {
      final sweep = usableAngle * fraction;
      if (sweep <= 0) continue;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + _gap;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter old) =>
      progress != old.progress ||
      proteinFraction != old.proteinFraction ||
      fatFraction != old.fatFraction ||
      carbsFraction != old.carbsFraction;
}

// ---------------------------------------------------------------------------
// Small atoms
// ---------------------------------------------------------------------------
class _MacroLabel extends StatelessWidget {
  final String value;
  final Color color;

  const _MacroLabel({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goal card
// ---------------------------------------------------------------------------
class _GoalCard extends StatelessWidget {
  final bool isMaintain;
  final String regularTitle;
  final String? maintainTitle;
  final String? maintainSubtitle;
  final String? fromWeight;
  final String? toWeight;
  final String? dateLine;
  final String? paceLine;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _GoalCard({
    required this.isMaintain,
    required this.regularTitle,
    required this.maintainTitle,
    required this.maintainSubtitle,
    required this.fromWeight,
    required this.toWeight,
    required this.dateLine,
    required this.paceLine,
    required this.cardBg,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconBg = AppColors.primary.withAlpha(25);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: isMaintain
                ? _buildMaintain(context, cs)
                : _buildLoseGain(context, cs),
          ),
        ],
      ),
    );
  }

  Widget _buildLoseGain(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          regularTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              fromWeight ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              toWeight ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (dateLine != null)
          Text(
            dateLine!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
              height: 1.3,
            ),
          ),
        if (paceLine != null) ...[
          const SizedBox(height: 4),
          Text(
            paceLine!,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMaintain(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(
          maintainTitle ?? '',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          maintainSubtitle ?? '',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Free vs Premium bridge card
// ---------------------------------------------------------------------------
class _BridgeCard extends StatelessWidget {
  final String title;
  final String freeLine;
  final String premiumLine;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _BridgeCard({
    required this.title,
    required this.freeLine,
    required this.premiumLine,
    required this.cardBg,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _BridgeLine(
            text: freeLine,
            iconColor: cs.onSurfaceVariant,
            textColor: cs.onSurfaceVariant,
            bold: false,
          ),
          const SizedBox(height: 8),
          _BridgeLine(
            text: premiumLine,
            iconColor: AppColors.primary,
            textColor: cs.onSurface,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _BridgeLine extends StatelessWidget {
  final String text;
  final Color iconColor;
  final Color textColor;
  final bool bold;

  const _BridgeLine({
    required this.text,
    required this.iconColor,
    required this.textColor,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable disclaimer
// ---------------------------------------------------------------------------
class _ExpandableDisclaimer extends StatelessWidget {
  final String shortText;
  final String fullText;
  final String expandLabel;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableDisclaimer({
    required this.shortText,
    required this.fullText,
    required this.expandLabel,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final disclaimerStyle = TextStyle(
      fontSize: 11,
      color: cs.onSurfaceVariant.withAlpha(170),
      height: 1.5,
    );
    final expandStyle = TextStyle(
      fontSize: 11,
      color: cs.onSurfaceVariant,
      decoration: TextDecoration.underline,
      height: 1.5,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'ⓘ  ', style: disclaimerStyle),
                TextSpan(text: shortText, style: disclaimerStyle),
                const TextSpan(text: '  ·  '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Text(expandLabel, style: expandStyle),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            Text(
              fullText,
              style: disclaimerStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
