import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/utils/macro_order.dart';
import 'package:meal_tracker/core/widgets/methodology_sources_sheet.dart';
import 'package:meal_tracker/features/onboarding/models/onboarding_data.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/obstacles_step.dart';

class ResultStep extends StatefulWidget {
  final OnboardingData data;

  const ResultStep({super.key, required this.data});

  @override
  State<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<ResultStep>
    with TickerProviderStateMixin {
  static const double _kgToLb = 2.20462;
  static const double _hPad = 16;

  // Macro arc palette — matches the AI meal-analysis donut so the user sees
  // the same color for each macro throughout the app. Source of truth:
  // _RingSegment colors in [ai_meal_result_sheet.dart].
  static const Color _proteinColor = Color(0xFFE4431C);
  static const Color _fatColor = Color(0xFFEFD400);
  static const Color _carbsColor = Color(0xFF17ACCC);

  static const String _proteinIcon = 'assets/icons/belok.svg';
  static const String _fatIcon = 'assets/icons/fat.svg';
  static const String _carbsIcon = 'assets/icons/uglevod.svg';

  static const String _laurelAsset = 'assets/onboarding/icons/laurel.svg';

  late final ConfettiController _confettiController;

  // Drives the donut sweep + macro count-up + goal weight count-up on
  // mount. A single controller keeps every animated element on the same
  // visual beat instead of N independent TweenAnimationBuilders drifting
  // out of sync by frame.
  late final AnimationController _entryController;

  // The weekly-progress bars wait for the user to scroll their card into
  // view before filling. We watch the scroll position and flip this once.
  final GlobalKey _milestonesKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _milestonesAnimated = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 600),
    );
    _confettiController.play();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    // Defer one frame so the AnimatedSwitcher slide-in finishes before
    // the donut starts sweeping — keeps both motions readable.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entryController.forward();
      _maybeTriggerMilestones();
    });
    _scrollController.addListener(_maybeTriggerMilestones);
  }

  /// Fires the milestone bar fill animation the first time the weekly
  /// progress card enters the viewport (or immediately on mount if it
  /// already does on small screens).
  void _maybeTriggerMilestones() {
    if (_milestonesAnimated) return;
    final ctx = _milestonesKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final position = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    // Treat the card as visible once its top edge crosses ~85% of the
    // viewport height — gives the bars a chance to start filling just as
    // the user is bringing them into focus.
    if (position.dy < screenHeight * 0.85) {
      setState(() => _milestonesAnimated = true);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatWeight(double kg) {
    if (widget.data.isImperial) {
      return '${(kg * _kgToLb).round()} lb';
    }
    return '${kg.round()} ${context.l10n.kgUnit}';
  }

  /// Signed weight change from the starting weight. Metric users always see
  /// kilograms — whole numbers when exact, otherwise one decimal place (so
  /// 0.5 reads as "0,5 kg" / "0.5 kg" per locale). Imperial users see
  /// pounds with one decimal. Uses unicode minus for sign-width parity.
  String _formatDelta(double currentKg, double startKg) {
    final delta = currentKg - startKg;
    if (delta.abs() < 0.05) return '0';
    final sign = delta > 0 ? '+' : '−';
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    if (widget.data.isImperial) {
      final lb = delta.abs() * _kgToLb;
      final formatter = NumberFormat('0.0', localeCode);
      return '$sign${formatter.format(lb)} lb';
    }
    final kg = delta.abs();
    final isWhole = (kg - kg.roundToDouble()).abs() < 0.05;
    final formatter = NumberFormat(isWhole ? '0' : '0.0', localeCode);
    return '$sign${formatter.format(kg)} ${context.l10n.kgUnit}';
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

  String _formatDate(BuildContext context, DateTime date) {
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMMd(localeCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    final data = widget.data;
    final goal = data.goal;
    final isMaintain = goal != 'lose' && goal != 'gain';

    final calories = data.calorieGoal?.round() ?? 0;
    final protein = data.proteinGoal?.round() ?? 0;
    final fat = data.fatGoal?.round() ?? 0;
    final carbs = data.carbsGoal?.round() ?? 0;

    final targetDate = data.targetDate ?? DateTime.now();
    final weeksToGoal = ((targetDate.difference(DateTime.now()).inHours) /
            (24 * 7))
        .ceil()
        .clamp(1, 9999);

    final l10n = context.l10n;
    final obstacleEntries = data.obstacles
        .map<({String label, String emoji, String tag})?>((k) {
          final label = ObstaclesStep.labelFor(l10n, k);
          final emoji = ObstaclesStep.emojiFor(k);
          final tag = ObstaclesStep.tagFor(l10n, k) ?? '';
          if (label == null) return null;
          return (label: label, emoji: emoji, tag: tag);
        })
        .whereType<({String label, String emoji, String tag})>()
        .toList(growable: false);

    // Custom milestone selection — fixed checkpoints (week 1, 3, 6) plus the
    // final goal week. Skip any checkpoint that lands on/after the goal so
    // the goal row is always the last bar and never duplicated.
    final milestones = <({int week, double weight, bool isGoal})>[];
    if (!isMaintain && data.weightLossKgPerWeek > 0) {
      final totalWeeks = ((data.weightKg - data.targetWeightKg).abs() /
              data.weightLossKgPerWeek)
          .ceil()
          .clamp(1, 9999);
      final direction = goal == 'lose' ? -1 : 1;
      for (final w in const [1, 3, 6]) {
        if (w >= totalWeeks) break;
        final wt = data.weightKg + direction * data.weightLossKgPerWeek * w;
        milestones.add((week: w, weight: wt, isGoal: false));
      }
      milestones.add((
        week: totalWeeks,
        weight: data.targetWeightKg,
        isGoal: true,
      ));
    }

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PlanSummaryCard(
                title: l10n.resultPlanReadyTitle,
                calories: calories,
                calorieUnit: l10n.kcalPerDay,
                proteinG: protein,
                fatG: fat,
                carbsG: carbs,
                gramsUnit: l10n.gramsUnit,
                proteinLabel: l10n.proteinLabel,
                fatLabel: l10n.fatLabel,
                carbsLabel: l10n.carbsLabel,
                footer: l10n.resultCanChange,
                tailoredFooter: l10n.resultTailoredFromAnswers(
                  widget.data.answeredCount,
                ),
                cardBg: cardBg,
                isDark: isDark,
                entryAnimation: _entryController,
                formatCalories: _formatCalories,
              ),
              const SizedBox(height: 12),

              _FadeSlideIn(
                delayMs: 120,
                child: isMaintain
                    ? _GoalMaintainCard(
                        text: l10n.resultMaintainCard(
                          _formatWeight(data.weightKg),
                        ),
                        cardBg: cardBg,
                      )
                    : _GoalCard(
                        reachLine: l10n.resultGoalReachLine(
                          _formatWeight(data.targetWeightKg),
                        ),
                        weightAccent: _formatWeight(data.targetWeightKg),
                        byDateLine: l10n.resultGoalByDateLine(
                          _formatDate(context, targetDate),
                        ),
                        inWeeksLine: l10n.resultGoalInWeeks(weeksToGoal),
                        cardBg: cardBg,
                      ),
              ),
              const SizedBox(height: 12),

              _FadeSlideIn(
                delayMs: 160,
                child: _BenefitsCard(
                  items: [
                    (
                      emoji: 'alarm-clock',
                      label: l10n.resultBenefit5MinDay,
                    ),
                    (
                      emoji: 'brain',
                      label: l10n.resultBenefitSmartTracking,
                    ),
                    (
                      emoji: 'fork-and-knife-with-plate',
                      label: l10n.resultBenefitTailored,
                    ),
                    (
                      emoji: 'four-leaf-clover',
                      label: l10n.resultBenefitSustainable,
                    ),
                  ],
                  cardBg: cardBg,
                ),
              ),
              const SizedBox(height: 12),

              if (!isMaintain && milestones.isNotEmpty) ...[
                _FadeSlideIn(
                  delayMs: 200,
                  child: _MilestonesCard(
                    key: _milestonesKey,
                    header: l10n.resultMilestonesHeader,
                    milestones: milestones,
                    startWeight: data.weightKg,
                    formatWeight: _formatWeight,
                    startLabel: l10n.resultStartLabel,
                    goalLabel: l10n.resultGoalRow,
                    weekLabelFor: (w) => l10n.resultWeekRow(w),
                    cardBg: cardBg,
                    animate: _milestonesAnimated,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (obstacleEntries.isNotEmpty) ...[
                _FadeSlideIn(
                  delayMs: 240,
                  child: _ObstaclesCard(
                    header: l10n.resultObstaclesHeader,
                    entries: obstacleEntries,
                    cardBg: cardBg,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // One-line disclaimer + inline "Sources" link, sitting right
              // above the FAQ card. Compliance footnote without taking up
              // a full card's worth of space.
              _DisclaimerLine(
                disclaimer: l10n.resultDisclaimerShort,
                sourcesLabel: l10n.resultSourcesTitle,
                onSourcesTap: () {
                  unawaited(
                    AnalyticsService.instance.logEvent(
                      'onboarding_result_methodology_opened',
                    ),
                  );
                  showMethodologySourcesSheet(context);
                },
              ),
              const SizedBox(height: 8),
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
// Plan summary — title + donut chart + macro pills + footer line.
// ---------------------------------------------------------------------------
class _PlanSummaryCard extends StatelessWidget {
  final String title;
  final int calories;
  final String calorieUnit;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final String gramsUnit;
  final String proteinLabel;
  final String fatLabel;
  final String carbsLabel;
  final String footer;
  final String tailoredFooter;
  final Color cardBg;
  final bool isDark;
  final Animation<double> entryAnimation;
  final String Function(int) formatCalories;

  const _PlanSummaryCard({
    required this.title,
    required this.calories,
    required this.calorieUnit,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.gramsUnit,
    required this.proteinLabel,
    required this.fatLabel,
    required this.carbsLabel,
    required this.footer,
    required this.tailoredFooter,
    required this.cardBg,
    required this.isDark,
    required this.entryAnimation,
    required this.formatCalories,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 24 / 18,
            ),
          ),
          const SizedBox(height: 18),
          _DonutWithMacros(
            calories: calories,
            calorieUnit: calorieUnit,
            proteinG: proteinG,
            fatG: fatG,
            carbsG: carbsG,
            gramsUnit: gramsUnit,
            proteinLabel: proteinLabel,
            fatLabel: fatLabel,
            carbsLabel: carbsLabel,
            entryAnimation: entryAnimation,
            formatCalories: formatCalories,
          ),
          const SizedBox(height: 16),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 18 / 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tailoredFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 18 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutWithMacros extends StatelessWidget {
  final int calories;
  final String calorieUnit;
  final int proteinG;
  final int fatG;
  final int carbsG;
  final String gramsUnit;
  final String proteinLabel;
  final String fatLabel;
  final String carbsLabel;
  final Animation<double> entryAnimation;
  final String Function(int) formatCalories;

  const _DonutWithMacros({
    required this.calories,
    required this.calorieUnit,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.gramsUnit,
    required this.proteinLabel,
    required this.fatLabel,
    required this.carbsLabel,
    required this.entryAnimation,
    required this.formatCalories,
  });

  @override
  Widget build(BuildContext context) {
    // Proportions reflect caloric contribution (4/9/4) — the same logic the
    // stats screen uses, so the macro mix here visually matches the rest of
    // the app once the user reaches the main flow.
    final pKcal = proteinG * 4;
    final fKcal = fatG * 9;
    final cKcal = carbsG * 4;
    final total = (pKcal + fKcal + cKcal).clamp(1, 1 << 30);

    final pFrac = pKcal / total;
    final fFrac = fKcal / total;
    final cFrac = cKcal / total;

    final order = MacroOrder.of(context);

    // Master controller is 0..1 linear; we split it into two phases so
    // the donut resolves first (centre number stops counting) and the
    // pastel pills then "land" one by one slightly after. Sub-curves are
    // computed per-element below.
    return AnimatedBuilder(
      animation: entryAnimation,
      builder: (context, _) {
        final tRaw = entryAnimation.value;
        // Phase 1 — donut + centre calorie text: 0 → ~65 % of timeline.
        final t =
            Curves.easeOutCubic.transform((tRaw / 0.65).clamp(0.0, 1.0));
        return Column(
          children: [
            SizedBox(
              width: 152,
              height: 152,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(152, 152),
                    painter: _MacroDonutPainter(
                      fractions: {
                        Macro.protein: pFrac * t,
                        Macro.fat: fFrac * t,
                        Macro.carbs: cFrac * t,
                      },
                      colors: const {
                        Macro.protein: _ResultStepState._proteinColor,
                        Macro.fat: _ResultStepState._fatColor,
                        Macro.carbs: _ResultStepState._carbsColor,
                      },
                      order: order,
                    ),
                  ),
                  // Fade the centre label in slightly behind the sweep so
                  // the donut visually leads.
                  Opacity(
                    opacity: t,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatCalories((calories * t).round()),
                            style: onboardingTitleStyle(
                              context,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 32 / 30,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          calorieUnit,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 16 / 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Phase 2 — each pastel pill drops in from above, decelerates
            // and "lands" with a tiny back-overshoot. Pills are
            // staggered ~80 ms apart so the trio settles into formation
            // rather than slamming down in unison. Order follows the
            // active locale (БЖУ on ru, Carbs-first elsewhere).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < order.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: i == 1 ? 16 : 0),
                      child: _LandingPill(
                        tRaw: tRaw,
                        index: i,
                        // Gram counter syncs with the donut sweep so the
                        // numbers stop climbing as the centre value
                        // freezes; the pill keeps descending after.
                        countT: t,
                        child: _pillFor(
                          order[i],
                          t: t,
                          proteinG: proteinG,
                          fatG: fatG,
                          carbsG: carbsG,
                          gramsUnit: gramsUnit,
                          proteinLabel: proteinLabel,
                          fatLabel: fatLabel,
                          carbsLabel: carbsLabel,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _pillFor(
    Macro m, {
    required double t,
    required int proteinG,
    required int fatG,
    required int carbsG,
    required String gramsUnit,
    required String proteinLabel,
    required String fatLabel,
    required String carbsLabel,
  }) {
    return switch (m) {
      Macro.protein => _PastelMacroPill(
          iconAsset: _ResultStepState._proteinIcon,
          label: proteinLabel,
          value: '${(proteinG * t).round()} $gramsUnit',
          bgColor: const Color(0xFFFFDFD5),
        ),
      Macro.fat => _PastelMacroPill(
          iconAsset: _ResultStepState._fatIcon,
          label: fatLabel,
          value: '${(fatG * t).round()} $gramsUnit',
          // Pastel matches the yellow Fat arc in the donut and the
          // shared BJU palette used across stats / AI meal sheet.
          bgColor: const Color(0xFFFFF5BB),
        ),
      Macro.carbs => _PastelMacroPill(
          iconAsset: _ResultStepState._carbsIcon,
          label: carbsLabel,
          value: '${(carbsG * t).round()} $gramsUnit',
          // Pastel matches the cyan Carbs arc in the donut.
          bgColor: const Color(0xFFC9F5F4),
        ),
    };
  }
}

class _PastelMacroPill extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;
  final Color bgColor;

  const _PastelMacroPill({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF0A1B39);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(iconAsset, width: 18, height: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textColor,
                    height: 14 / 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 20 / 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a pastel macro pill in a staggered "spacecraft landing" entry:
/// each pill descends from above, decelerates with a tiny back-overshoot,
/// and settles into its target slot. The earlier the [index], the earlier
/// the pill begins its approach — staggers feel like a formation
/// touchdown instead of three pills slamming down in unison.
class _LandingPill extends StatelessWidget {
  final double tRaw;
  final int index;
  final double countT;
  final Widget child;

  const _LandingPill({
    required this.tRaw,
    required this.index,
    required this.countT,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Pills begin their descent shortly after the donut has started
    // sweeping — at 0.18 of the master timeline, with a ~60 ms stagger
    // between siblings so they don't all touch down at the same instant.
    final subStart = 0.18 + 0.05 * index;
    final subT =
        ((tRaw - subStart) / (1 - subStart)).clamp(0.0, 1.0);

    // Position: smooth deceleration — no overshoot here so the pill
    // doesn't visibly bounce up at the end.
    final posT = Curves.easeOutCubic.transform(subT);
    // Scale: easeOutBack gives the small touch-down springiness on
    // arrival without affecting where the pill actually lands.
    final scaleT = Curves.easeOutBack.transform(subT);
    // Opacity catches up faster than position so the pill is fully
    // visible halfway through its descent.
    final opacity = Curves.easeOut.transform(subT.clamp(0.0, 1.0));

    // Outer pills drift in from slightly outside, middle pill drops
    // straight down — together they read as a formation closing on
    // the donut.
    final xOrigin = switch (index) {
      0 => -14.0,
      2 => 14.0,
      _ => 0.0,
    };
    final yOffset = (1 - posT) * -36;
    final xOffset = (1 - posT) * xOrigin;
    final scale = 0.86 + scaleT * 0.14;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(xOffset, yOffset),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          // [countT] is only forwarded to keep the pill's number ticker
          // synced with the donut (handled by the parent caller).
          child: child,
        ),
      ),
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  /// Macro → arc fraction of the ring (0..1).
  final Map<Macro, double> fractions;

  /// Macro → arc color.
  final Map<Macro, Color> colors;

  /// Clockwise order to draw the arcs in, starting from 12 o'clock.
  final List<Macro> order;

  _MacroDonutPainter({
    required this.fractions,
    required this.colors,
    required this.order,
  });

  static const double _gapPx = 4;
  static const double _strokeWidth = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2 - _strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final fullCircle = 2 * math.pi;
    // Convert the requested gap in pixels into an angle at the current
    // radius so the visual gap stays exactly _gapPx wide regardless of
    // ring size.
    final gapRadians = _gapPx / radius;
    final totalGap = gapRadians * 3;
    final usable = fullCircle - totalGap;

    double start = -math.pi / 2 + gapRadians / 2;
    for (final m in order) {
      final sweep =
          (usable * (fractions[m] ?? 0)).clamp(0.0, fullCircle);
      final paint = Paint()
        ..color = colors[m] ?? const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = _strokeWidth;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gapRadians;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter old) {
    if (old.order.length != order.length) return true;
    for (int i = 0; i < order.length; i++) {
      if (old.order[i] != order[i]) return true;
    }
    for (final m in order) {
      if (old.fractions[m] != fractions[m]) return true;
      if (old.colors[m] != colors[m]) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Goal card — "You'll reach 65 kg / by <date> / in N weeks" with two laurels.
// ---------------------------------------------------------------------------
class _GoalCard extends StatelessWidget {
  final String reachLine;
  final String weightAccent;
  final String byDateLine;
  final String inWeeksLine;
  final Color cardBg;

  const _GoalCard({
    required this.reachLine,
    required this.weightAccent,
    required this.byDateLine,
    required this.inWeeksLine,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final accentColor = AppColors.green;

    // Split the reach line on the weight so we can render the weight in the
    // accent colour while keeping the rest of the sentence in the surface
    // colour. Falls back to a single span if the placeholder is missing.
    final accentIndex = reachLine.indexOf(weightAccent);
    final hasAccent = accentIndex >= 0;
    final beforeAccent =
        hasAccent ? reachLine.substring(0, accentIndex) : reachLine;
    final afterAccent = hasAccent
        ? reachLine.substring(accentIndex + weightAccent.length)
        : '';

    final reachStyle = onboardingTitleStyle(
      context,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 28 / 22,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            bottom: 4,
            child: SvgPicture.asset(
              _ResultStepState._laurelAsset,
              width: 22,
              height: 50,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            bottom: 4,
            child: Transform.flip(
              flipX: true,
              child: SvgPicture.asset(
                _ResultStepState._laurelAsset,
                width: 22,
                height: 50,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    style: reachStyle,
                    children: [
                      TextSpan(text: beforeAccent),
                      TextSpan(
                        text: weightAccent,
                        style: reachStyle.copyWith(color: accentColor),
                      ),
                      if (afterAccent.isNotEmpty) TextSpan(text: afterAccent),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  byDateLine,
                  textAlign: TextAlign.center,
                  style: reachStyle,
                ),
                const SizedBox(height: 6),
                Text(
                  inWeeksLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurfaceVariant,
                    height: 20 / 15,
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

class _GoalMaintainCard extends StatelessWidget {
  final String text;
  final Color cardBg;

  const _GoalMaintainCard({required this.text, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                height: 22 / 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan benefits — emoji bullets list.
// ---------------------------------------------------------------------------
class _BenefitsCard extends StatelessWidget {
  final List<({String emoji, String label})> items;
  final Color cardBg;

  const _BenefitsCard({required this.items, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Gray surface card per Figma (#F5F6F8) — visually distinct from
    // the white stat cards above/below; no border, no baseDrop.
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightScaffold;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NotoEmoji(name: items[i].emoji, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      height: 20 / 15,
                    ),
                  ),
                ),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly progress — bars fill up as the user moves toward the goal (goal
// row is the fullest). Trailing column shows the signed weight delta from
// the starting weight rather than the absolute weight at that week.
// ---------------------------------------------------------------------------
class _MilestonesCard extends StatelessWidget {
  final String header;
  final List<({int week, double weight, bool isGoal})> milestones;
  final double startWeight;
  final String Function(double) formatWeight;
  final String startLabel;
  final String goalLabel;
  final String Function(int) weekLabelFor;
  final Color cardBg;
  /// Flipped to true once the card first enters the viewport — bars stay
  /// at zero width until then so the fill animation plays in front of the
  /// user instead of off-screen.
  final bool animate;

  const _MilestonesCard({
    super.key,
    required this.header,
    required this.milestones,
    required this.startWeight,
    required this.formatWeight,
    required this.startLabel,
    required this.goalLabel,
    required this.weekLabelFor,
    required this.cardBg,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    // Progress is measured against the goal week so the goal row always
    // fills the full bar regardless of how many intermediate checkpoints
    // exist before it.
    final goalWeek = milestones.last.week;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
        boxShadow: AppColors.baseDrop,
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: onboardingTitleStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 24 / 18,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < milestones.length; i++) ...[
            () {
              final m = milestones[i];
              final progress = goalWeek == 0
                  ? 1.0
                  : (m.week / goalWeek).clamp(0.0, 1.0);
              // Value prefix: "Start" for the very first row, "100%"
              // for the goal, percentage otherwise.
              final prefix = m.isGoal
                  ? '100%'
                  : (i == 0 ? startLabel : '${(progress * 100).round()}%');
              return _MilestoneRow(
                label: m.isGoal ? goalLabel : weekLabelFor(m.week),
                weight: m.weight,
                isFinal: m.isGoal,
                progress: progress,
                valueText: '$prefix · ${formatWeight(m.weight)}',
                barTrackColor: isDark
                    ? AppColors.lineDT100
                    : AppColors.lineLight200,
                animate: animate,
                rowIndex: i,
              );
            }(),
            if (i != milestones.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final String label;
  final double weight;
  final bool isFinal;
  final double progress;
  final String valueText;
  final Color barTrackColor;
  final bool animate;
  final int rowIndex;

  const _MilestoneRow({
    required this.label,
    required this.weight,
    required this.isFinal,
    required this.progress,
    required this.valueText,
    required this.barTrackColor,
    required this.animate,
    required this.rowIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final targetWidth = progress.clamp(0.07, 1.0);
    // 150 ms cascade — each row starts filling ~150 ms after the one
    // above it. Total card animation lands inside ~1.1 s.
    final staggerMs = 150 * rowIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isFinal ? FontWeight.w600 : FontWeight.w400,
                  color: isFinal ? cs.onSurface : cs.onSurfaceVariant,
                  height: 18 / 14,
                ),
              ),
            ),
            // Delta count-up — uses the same easing as the bar so the
            // number lands exactly when the bar stops.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                animate ? valueText : '',
                key: ValueKey(animate ? valueText : '__pending'),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                  height: 18 / 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 12,
                color: barTrackColor,
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: animate ? targetWidth : 0.0),
                duration: Duration(milliseconds: 800 + staggerMs),
                curve: Interval(
                  // Cascade: rows below the first wait their stagger out
                  // before starting to grow.
                  staggerMs / (800 + staggerMs),
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 12,
                      color: isFinal
                          ? AppColors.success
                          : AppColors.onboardingCtaBg,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Your plan accounts for" — the user's chosen obstacles, prefixed with the
// same emoji shown back on the obstacles step.
// ---------------------------------------------------------------------------
class _ObstaclesCard extends StatelessWidget {
  final String header;
  final List<({String label, String emoji, String tag})> entries;
  final Color cardBg;

  const _ObstaclesCard({
    required this.header,
    required this.entries,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Gray surface card per Figma (#F5F6F8) — matches the benefits card
    // tone above; no border, no baseDrop.
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightScaffold;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: onboardingTitleStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 24 / 18,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                NotoEmoji(name: entries[i].emoji, size: 22),
                const SizedBox(width: 10),
                // Label takes the remaining width minus the tag column;
                // [Expanded] before the tag lets the label wrap to two
                // lines on the very widest locales (e.g. RU "Сложно
                // держаться плана") without pushing the tag off the row.
                Expanded(
                  child: Text(
                    entries[i].label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                      height: 20 / 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Right-aligned tag — short feature reference (≤12 chars
                // in EN, translation budget honoured across locales) that
                // tells the user how the app handles this specific blocker.
                // Muted colour + medium weight keeps it visible but
                // secondary to the obstacle label itself.
                Text(
                  entries[i].tag,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                    height: 18 / 13,
                  ),
                ),
              ],
            ),
            if (i != entries.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Minimal compliance line — one row, single line: a short "not medical
// advice" notice followed by a "Sources" tap target. Sits just above the
// FAQ. App Store 1.4.1 still satisfied because tapping "Sources" opens the
// full methodology sheet with the long-form citations.
// ---------------------------------------------------------------------------
class _DisclaimerLine extends StatelessWidget {
  final String disclaimer;
  final String sourcesLabel;
  final VoidCallback onSourcesTap;

  const _DisclaimerLine({
    required this.disclaimer,
    required this.sourcesLabel,
    required this.onSourcesTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = cs.onSurfaceVariant;
    final linkColor = cs.onSurface;

    // Single line, auto-shrinks on extra-long locales rather than wrapping
    // to two rows — keeps the row consistently slim.
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSourcesTap,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$disclaimer ',
                  style: TextStyle(
                    fontSize: 12,
                    color: baseColor,
                    height: 16 / 12,
                  ),
                ),
                TextSpan(
                  text: sourcesLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: linkColor,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subtle entrance — fades a card in and lifts it up by a few pixels after a
// small delay. Used to cascade the secondary cards (goal, benefits,
// milestones, obstacles, FAQ) so the page lands in waves instead of all at
// once.
// ---------------------------------------------------------------------------
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;

  const _FadeSlideIn({
    required this.child,
    this.delayMs = 0,
  }) : durationMs = 420;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  // Starts at false so the very first build paints the offset/transparent
  // state. We flip it inside a post-frame callback, which schedules the
  // implicit-animation rebuild and lets [AnimatedOpacity] /
  // [AnimatedSlide] interpolate to the resting pose.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: Duration(milliseconds: widget.durationMs),
      curve: Curves.easeOutCubic,
      offset: _shown ? Offset.zero : const Offset(0, 0.04),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: widget.durationMs),
        curve: Curves.easeOut,
        opacity: _shown ? 1.0 : 0.0,
        child: widget.child,
      ),
    );
  }
}
