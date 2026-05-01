import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

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
    // Treat any unknown / null goal as "maintain" so we render the
    // simpler maintain-style goal card.
    final isMaintain = goal != 'lose' && goal != 'gain';

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // --- Section 1: Hero card (title + calorie target + mascot) ---
              AnimatedBuilder(
                animation: _animation ?? const AlwaysStoppedAnimation(1.0),
                builder: (context, _) {
                  final p = _progress;
                  final animCal = (calories * p).round();
                  return _HeroCard(
                    title: context.l10n.resultPlanReadyTitle,
                    subtitle: context.l10n.resultHeroSubtitle,
                    goalLabel: context.l10n.resultGoalCardTitle,
                    calorieValue: _formatCalories(animCal),
                    unit: context.l10n.kcalPerDay,
                    cardBg: cardBg,
                    lineColor: lineColor,
                    isDark: isDark,
                  );
                },
              ),
              const SizedBox(height: 12),

              // --- Section 2: Macro card (segmented bar + per-macro stats) ---
              AnimatedBuilder(
                animation: _animation ?? const AlwaysStoppedAnimation(1.0),
                builder: (context, _) {
                  final p = _progress;
                  return _MacroCard(
                    progress: p,
                    proteinGrams: (protein * p).round(),
                    carbsGrams: (carbs * p).round(),
                    fatGrams: (fat * p).round(),
                    proteinPct: proteinPct,
                    carbsPct: carbsPct,
                    fatPct: fatPct,
                    proteinFraction: totalGrams > 0
                        ? protein / totalGrams
                        : 0.33,
                    carbsFraction: totalGrams > 0
                        ? carbs / totalGrams
                        : 0.34,
                    fatFraction: totalGrams > 0 ? fat / totalGrams : 0.33,
                    proteinLabel: context.l10n.proteinLabel,
                    carbsLabel: context.l10n.carbsLabel,
                    fatLabel: context.l10n.fatLabel,
                    gramsUnit: context.l10n.gramsUnit,
                    adjustLine: context.l10n.resultRingAdjustLine,
                    cardBg: cardBg,
                    lineColor: lineColor,
                    isDark: isDark,
                  );
                },
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
                cardBg: cardBg,
                lineColor: lineColor,
                isDark: isDark,
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
// Hero card: title + tagline + big calorie target + mascot illustration slot
// ---------------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String goalLabel;
  final String calorieValue;
  final String unit;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.goalLabel,
    required this.calorieValue,
    required this.unit,
    required this.cardBg,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: lineColor),
            const SizedBox(height: 16),
            Text(
              goalLabel,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              calorieValue,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Macro card: segmented horizontal bar + per-macro stats + adjust footer
// ---------------------------------------------------------------------------
class _MacroCard extends StatelessWidget {
  final double progress;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int proteinPct;
  final int carbsPct;
  final int fatPct;
  final double proteinFraction;
  final double carbsFraction;
  final double fatFraction;
  final String proteinLabel;
  final String carbsLabel;
  final String fatLabel;
  final String gramsUnit;
  final String adjustLine;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _MacroCard({
    required this.progress,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.proteinFraction,
    required this.carbsFraction,
    required this.fatFraction,
    required this.proteinLabel,
    required this.carbsLabel,
    required this.fatLabel,
    required this.gramsUnit,
    required this.adjustLine,
    required this.cardBg,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: 20,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SegmentedMacroBar(
                  progress: progress,
                  proteinFraction: proteinFraction,
                  carbsFraction: carbsFraction,
                  fatFraction: fatFraction,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MacroStatColumn(
                        label: proteinLabel,
                        dotColor: AppColors.blue,
                        value: '$proteinGrams $gramsUnit',
                        percent: '$proteinPct%',
                      ),
                    ),
                    Expanded(
                      child: _MacroStatColumn(
                        label: carbsLabel,
                        dotColor: AppColors.green,
                        value: '$carbsGrams $gramsUnit',
                        percent: '$carbsPct%',
                      ),
                    ),
                    Expanded(
                      child: _MacroStatColumn(
                        label: fatLabel,
                        dotColor: AppColors.orange,
                        value: '$fatGrams $gramsUnit',
                        percent: '$fatPct%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: lineColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    adjustLine,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal pill bar split into 3 colored segments (protein / carbs /
/// fat) with small gaps. Animates a left-to-right reveal driven by
/// [progress] (0..1).
class _SegmentedMacroBar extends StatelessWidget {
  final double progress;
  final double proteinFraction;
  final double carbsFraction;
  final double fatFraction;

  const _SegmentedMacroBar({
    required this.progress,
    required this.proteinFraction,
    required this.carbsFraction,
    required this.fatFraction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: CustomPaint(
        size: Size.infinite,
        painter: _MacroBarPainter(
          progress: progress,
          proteinFraction: proteinFraction,
          carbsFraction: carbsFraction,
          fatFraction: fatFraction,
        ),
      ),
    );
  }
}

class _MacroBarPainter extends CustomPainter {
  static const _gap = 4.0;

  final double progress;
  final double proteinFraction;
  final double carbsFraction;
  final double fatFraction;

  _MacroBarPainter({
    required this.progress,
    required this.proteinFraction,
    required this.carbsFraction,
    required this.fatFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = Radius.circular(h / 2);
    final usable = (w - _gap * 2).clamp(0, w).toDouble();

    final pW = usable * proteinFraction;
    final cW = usable * carbsFraction;
    final fW = usable * fatFraction;

    final segments = <(double, double, Color)>[
      (0.0, pW, AppColors.blue),
      (pW + _gap, cW, AppColors.green),
      (pW + _gap + cW + _gap, fW, AppColors.orange),
    ];

    final visibleEnd = w * progress.clamp(0.0, 1.0);
    if (visibleEnd <= 0) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, visibleEnd, h));

    for (final (start, segWidth, color) in segments) {
      if (segWidth <= 0) continue;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(start, 0, segWidth, h),
        radius,
      );
      canvas.drawRRect(rrect, Paint()..color = color);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MacroBarPainter old) =>
      progress != old.progress ||
      proteinFraction != old.proteinFraction ||
      carbsFraction != old.carbsFraction ||
      fatFraction != old.fatFraction;
}

class _MacroStatColumn extends StatelessWidget {
  final String label;
  final Color dotColor;
  final String value;
  final String percent;

  const _MacroStatColumn({
    required this.label,
    required this.dotColor,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              TextSpan(
                text: ' ($percent)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
