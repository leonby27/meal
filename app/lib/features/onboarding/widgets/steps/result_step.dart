import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/methodology_sources.dart';
import 'package:meal_tracker/features/onboarding/models/onboarding_data.dart';

class ResultStep extends StatefulWidget {
  final OnboardingData data;

  const ResultStep({super.key, required this.data});

  @override
  State<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<ResultStep> with TickerProviderStateMixin {
  static const String _planImageLight = 'assets/onboarding/light/plan.png';
  static const String _planImageDark = 'assets/onboarding/dark/plan.png';
  static const double _planImageAspectRatio = 1572 / 808;
  static const double _planCardOverlap = 44;

  // Conversion factor used to format weights for users on imperial units.
  // The internal data model is always kg; we only convert for display.
  static const double _kgToLb = 2.20462;

  // Unified visual rhythm.
  static const double _cardRadius = 20;
  static const double _hPad = 16;

  AnimationController? _controller;
  Animation<double>? _animation;
  late final ConfettiController _confettiController;

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

  /// Localized signed delta string for the goal card badge, e.g. "−5 kg"
  /// for lose or "+3 kg" for gain. Sign is rendered with a typographic
  /// minus (U+2212) so it lines up well with bold numerals.
  String _formatDelta(double currentKg, double targetKg) {
    final deltaKg = targetKg - currentKg;
    final unit = widget.data.isImperial ? 'lb' : context.l10n.kgUnit;
    final value = widget.data.isImperial
        ? (deltaKg.abs() * _kgToLb).round()
        : deltaKg.abs().round();
    final sign = deltaKg > 0 ? '+' : '\u2212';
    return '$sign$value $unit';
  }

  String _formatCalories(int cal) {
    if (cal >= 1000) {
      final whole = cal ~/ 1000;
      final rest = cal % 1000;
      // Non-breaking space so the thousand-separator never wraps.
      if (rest == 0) return '$whole\u00A0000';
      return '$whole\u00A0${rest.toString().padLeft(3, '0')}';
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
    final proteinPct = totalGrams > 0
        ? ((protein / totalGrams) * 100).round()
        : 0;
    final fatPct = totalGrams > 0 ? ((fat / totalGrams) * 100).round() : 0;
    final carbsPct = totalGrams > 0 ? ((carbs / totalGrams) * 100).round() : 0;

    final goal = widget.data.goal;
    // Treat any unknown / null goal as "maintain" so we render the
    // simpler maintain-style goal card.
    final isMaintain = goal != 'lose' && goal != 'gain';
    final isLose = goal == 'lose';
    final planImage = isDark ? _planImageDark : _planImageLight;

    return Stack(
      children: [
        SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageHeight = constraints.maxWidth / _planImageAspectRatio;

              return Stack(
                children: [
                  Image.asset(
                    planImage,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _hPad,
                      imageHeight - _planCardOverlap,
                      _hPad,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- Hero: title + animated calorie ring (kcal/day in center) ---
                        AnimatedBuilder(
                          animation:
                              _animation ?? const AlwaysStoppedAnimation(1.0),
                          builder: (context, _) {
                            final p = _progress;
                            final animCal = (calories * p).round();
                            return _HeroCard(
                              title: context.l10n.resultPlanReadyTitle,
                              subtitle: context.l10n.resultHeroSubtitle,
                              calorieValue: _formatCalories(animCal),
                              unit: context.l10n.kcalPerDay,
                              progress: p,
                              cardBg: cardBg,
                              lineColor: lineColor,
                              isDark: isDark,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // --- Macros: slim segmented bar + 3 centered macro columns ---
                        AnimatedBuilder(
                          animation:
                              _animation ?? const AlwaysStoppedAnimation(1.0),
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
                              fatFraction: totalGrams > 0
                                  ? fat / totalGrams
                                  : 0.33,
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
                        const SizedBox(height: 24),

                        // --- Goal card (lose/gain → arrow + delta badge; maintain → text) ---
                        _GoalCard(
                          isMaintain: isMaintain,
                          isLose: isLose,
                          regularTitle: context.l10n.resultGoalCardTitle,
                          maintainTitle: isMaintain
                              ? context.l10n.resultGoalMaintainTitle(
                                  _formatWeight(widget.data.weightKg),
                                )
                              : null,
                          maintainSubtitle: isMaintain
                              ? context.l10n.resultGoalMaintainSubtitle
                              : null,
                          fromWeight: isMaintain
                              ? null
                              : _formatWeight(widget.data.weightKg),
                          toWeight: isMaintain
                              ? null
                              : _formatWeight(widget.data.targetWeightKg),
                          deltaLabel: isMaintain
                              ? null
                              : _formatDelta(
                                  widget.data.weightKg,
                                  widget.data.targetWeightKg,
                                ),
                          cardBg: cardBg,
                          lineColor: lineColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),

                        // --- Free vs Premium bridge (premium line gets primary accent) ---
                        _BridgeCard(
                          title: context.l10n.resultBridgeTitle,
                          freeLine: context.l10n.resultBridgeFreeLine,
                          premiumLine: context.l10n.resultBridgePremiumLine,
                          cardBg: cardBg,
                          lineColor: lineColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // --- Methodology zone: disclaimer + scientific citations ---
                        _MethodologyBlock(
                          disclaimerLabel: context.l10n.resultDisclaimerShort,
                          disclaimerText: context.l10n.resultDisclaimer,
                          caloriesLabel: context.l10n.resultSourceCaloriesLabel,
                          macrosLabel: context.l10n.resultSourceMacrosLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
// Hero card
// ---------------------------------------------------------------------------
// Anchors the page on a single hero artifact: the daily calorie target
// rendered as a count-up number inside an animated circular ring. This
// matches the "moment of completion" pattern used by Cal AI / MyFitnessPal /
// Yazio result screens, and previews the goal-ring metaphor users will see
// in the diary screen.
// ---------------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String calorieValue;
  final String unit;

  /// 0..1 — drives both the kcal count-up (in the parent) and the ring fill.
  final double progress;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.calorieValue,
    required this.unit,
    required this.progress,
    required this.cardBg,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringTrack = isDark
        ? Colors.white.withAlpha(18)
        : AppColors.primary.withAlpha(20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_ResultStepState._cardRadius),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: _ResultStepState._cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.25,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 168,
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: CircularProgressIndicator(
                      // The ring fills in with the same controller that drives
                      // the kcal count-up so they read as one moment.
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: ringTrack,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            calorieValue,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1.0,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          unit,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Macro card: slim segmented bar + 3 centered macro columns + adjust footer
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
        borderRadius: BorderRadius.circular(_ResultStepState._cardRadius),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: _ResultStepState._cardRadius,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SegmentedMacroBar(
                  progress: progress,
                  proteinFraction: proteinFraction,
                  carbsFraction: carbsFraction,
                  fatFraction: fatFraction,
                ),
                const SizedBox(height: 22),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _MacroStatColumn(
                          label: proteinLabel,
                          dotColor: AppColors.blue,
                          value: '$proteinGrams\u00A0$gramsUnit',
                          percent: '$proteinPct%',
                        ),
                      ),
                      _ColumnDivider(color: lineColor),
                      Expanded(
                        child: _MacroStatColumn(
                          label: carbsLabel,
                          dotColor: AppColors.green,
                          value: '$carbsGrams\u00A0$gramsUnit',
                          percent: '$carbsPct%',
                        ),
                      ),
                      _ColumnDivider(color: lineColor),
                      Expanded(
                        child: _MacroStatColumn(
                          label: fatLabel,
                          dotColor: AppColors.orange,
                          value: '$fatGrams\u00A0$gramsUnit',
                          percent: '$fatPct%',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: lineColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }
}

class _ColumnDivider extends StatelessWidget {
  final Color color;
  const _ColumnDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(width: 1, color: color),
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
      height: 8,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          percent,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goal card
// ---------------------------------------------------------------------------
// Lose / gain: weight from → weight to with a colored delta badge that
// matches the goal direction (orange for lose, green for gain).
// Maintain: short two-line text card with the same icon-on-left layout.
// ---------------------------------------------------------------------------
class _GoalCard extends StatelessWidget {
  final bool isMaintain;
  final bool isLose;
  final String regularTitle;
  final String? maintainTitle;
  final String? maintainSubtitle;
  final String? fromWeight;
  final String? toWeight;
  final String? deltaLabel;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _GoalCard({
    required this.isMaintain,
    required this.isLose,
    required this.regularTitle,
    required this.maintainTitle,
    required this.maintainSubtitle,
    required this.fromWeight,
    required this.toWeight,
    required this.deltaLabel,
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
        borderRadius: BorderRadius.circular(_ResultStepState._cardRadius),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: _ResultStepState._cardRadius,
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
    // Orange = lose direction (matches food/calorie semantics in this app),
    // green = gain direction. Both stay within the existing palette.
    final deltaColor = isLose ? AppColors.orange : AppColors.green;
    final deltaBg = isLose
        ? AppColors.orange.withAlpha(28)
        : AppColors.green.withAlpha(28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                regularTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (deltaLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: deltaBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deltaLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: deltaColor,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              fromWeight ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              toWeight ?? '',
              style: const TextStyle(
                fontSize: 20,
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
// The premium row sits inside its own subtle primary-tinted container with
// a thicker left accent bar — gives it clear visual priority over the free
// row without needing a new CTA in this section.
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
    final premiumBg = isDark
        ? AppColors.primary.withAlpha(28)
        : AppColors.primary.withAlpha(18);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_ResultStepState._cardRadius),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: _ResultStepState._cardRadius,
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
          const SizedBox(height: 14),
          // Free — muted plain row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    freeLine,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Premium — accented row with primary tint and crown icon.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: premiumBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          premiumLine,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Always-visible methodology block: the health disclaimer and scientific
// sources behind the daily calorie / macronutrient recommendations. Required
// by App Store Review guideline 1.4.1 (citations for in-app health/medical
// calculations).
// ---------------------------------------------------------------------------
class _MethodologyBlock extends StatelessWidget {
  final String disclaimerLabel;
  final String disclaimerText;
  final String caloriesLabel;
  final String macrosLabel;

  const _MethodologyBlock({
    required this.disclaimerLabel,
    required this.disclaimerText,
    required this.caloriesLabel,
    required this.macrosLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
      height: 1.28,
    );
    final bodyStyle = TextStyle(
      fontSize: 11,
      color: cs.onSurfaceVariant.withAlpha(170),
      height: 1.32,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MethodologyLine(
          label: disclaimerLabel,
          text: disclaimerText,
          labelStyle: labelStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 7),
        _MethodologyLine(
          label: caloriesLabel,
          text: kMethodologyCitationCalories,
          labelStyle: labelStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 7),
        _MethodologyLine(
          label: macrosLabel,
          text: kMethodologyCitationMacros,
          labelStyle: labelStyle,
          bodyStyle: bodyStyle,
        ),
      ],
    );
  }
}

class _MethodologyLine extends StatelessWidget {
  final String label;
  final String text;
  final TextStyle labelStyle;
  final TextStyle bodyStyle;

  const _MethodologyLine({
    required this.label,
    required this.text,
    required this.labelStyle,
    required this.bodyStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label — ', style: labelStyle),
          TextSpan(text: text, style: bodyStyle),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}
