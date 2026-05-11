import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/widgets/methodology_sources_sheet.dart';
import 'package:meal_tracker/features/onboarding/models/onboarding_data.dart';
import 'package:meal_tracker/features/onboarding/services/psychotype.dart';
import 'package:meal_tracker/features/onboarding/services/tdee_calculator.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/obstacles_step.dart';

class ResultStep extends StatefulWidget {
  final OnboardingData data;

  const ResultStep({super.key, required this.data});

  @override
  State<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<ResultStep> {
  static const String _planImageLight = 'assets/onboarding/light/plan.png';
  static const String _planImageDark = 'assets/onboarding/dark/plan.png';
  static const double _planImageAspectRatio = 1572 / 808;
  // No overlap between the hero illustration and the content below —
  // the title now sits cleanly under the image.
  static const double _planCardOverlap = -16;

  // Conversion factor used to format weights for users on imperial units.
  // The internal data model is always kg; we only convert for display.
  static const double _kgToLb = 2.20462;
  static const double _hPad = 16;
  static const double _cardRadius = 20;

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 600),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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
      // Non-breaking space so the thousand-separator never wraps.
      if (rest == 0) return '$whole 000';
      return '$whole ${rest.toString().padLeft(3, '0')}';
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
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    final data = widget.data;
    final goal = data.goal;
    final isMaintain = goal != 'lose' && goal != 'gain';

    final calories = data.calorieGoal?.round() ?? 0;
    final protein = data.proteinGoal?.round() ?? 0;
    final fat = data.fatGoal?.round() ?? 0;
    final carbs = data.carbsGoal?.round() ?? 0;

    final targetDate = data.targetDate ?? DateTime.now();
    final weeksToGoal = ((targetDate.difference(DateTime.now()).inHours) / (24 * 7))
        .ceil()
        .clamp(0, 9999);

    final planImage = isDark ? _planImageDark : _planImageLight;
    final l10n = context.l10n;
    final psychotype = Psychotype.infoFor(l10n, data.psychotype);
    final obstacleLabels = data.obstacles
        .map((k) => ObstaclesStep.labelFor(l10n, k))
        .whereType<String>()
        .toList(growable: false);

    final milestones = TdeeCalculator.generateMilestones(
      currentWeight: data.weightKg,
      targetWeight: data.targetWeightKg,
      weightLossKgPerWeek: data.weightLossKgPerWeek,
      goal: goal ?? 'maintain',
    );

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
                        // 1. Hero header.
                        //
                        // No emoji prefix — Momo Trust Display (used for
                        // English titles) lacks emoji glyphs, so 🎉 was
                        // rendering as a "tofu" missing-glyph box.
                        // Confetti animation conveys the celebration.
                        Text(
                          context.l10n.resultPlanReadyTitle,
                          textAlign: TextAlign.center,
                          style: onboardingTitleStyle(
                            context,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. Anchor date / maintain card
                        if (isMaintain)
                          _MaintainCard(
                            text: l10n.resultMaintainCard(
                              _formatWeight(data.weightKg),
                            ),
                            cardBg: cardBg,
                            lineColor: lineColor,
                            isDark: isDark,
                          )
                        else
                          _AnchorDateCard(
                            label: l10n.resultAnchorPrefix(
                              _formatWeight(data.targetWeightKg),
                            ),
                            dateText: _formatDate(context, targetDate),
                            weeksSuffix:
                                l10n.resultAnchorWeeksSuffix(weeksToGoal),
                            isDark: isDark,
                          ),
                        const SizedBox(height: 24),

                        // 3. Daily calorie norm
                        _CaloriesBlock(
                          value: _formatCalories(calories),
                          unitLabel: l10n.resultDailyNormLabel,
                          unitTrailing: l10n.kcalPerDay,
                        ),
                        const SizedBox(height: 24),

                        // 4. Macros
                        _MacrosRow(
                          proteinG: protein,
                          fatG: fat,
                          carbsG: carbs,
                          gramsUnit: context.l10n.gramsUnit,
                          proteinLabel: context.l10n.proteinLabel,
                          fatLabel: context.l10n.fatLabel,
                          carbsLabel: context.l10n.carbsLabel,
                        ),
                        const SizedBox(height: 24),

                        // 5. Psychotype card
                        _PsychotypeCard(
                          title: psychotype.title,
                          description: psychotype.description,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // 6. Obstacles ("your plan takes into account")
                        if (obstacleLabels.isNotEmpty) ...[
                          _ObstaclesBlock(labels: obstacleLabels),
                          const SizedBox(height: 16),
                        ],

                        // 7. Milestone preview (lose/gain only)
                        if (!isMaintain && milestones.isNotEmpty) ...[
                          _MilestonesCard(
                            milestones: milestones,
                            startWeight: data.weightKg,
                            targetWeight: data.targetWeightKg,
                            formatWeight: _formatWeight,
                            cardBg: cardBg,
                            lineColor: lineColor,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Methodology block — App Store 1.4.1 compliance.
                        _MethodologyBlock(
                          disclaimerLabel: context.l10n.resultDisclaimerShort,
                          disclaimerText: context.l10n.resultDisclaimer,
                          sourcesLabel: context.l10n.resultSourcesCta,
                          onSourcesTap: () =>
                              showMethodologySourcesSheet(context),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Confetti at peak excitement.
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
// 2. Anchor date — the single most important visual element on the screen.
// ---------------------------------------------------------------------------
class _AnchorDateCard extends StatelessWidget {
  final String label;
  final String dateText;
  final String weeksSuffix;
  final bool isDark;

  const _AnchorDateCard({
    required this.label,
    required this.dateText,
    required this.weeksSuffix,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dateText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weeksSuffix,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintainCard extends StatelessWidget {
  final String text;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _MaintainCard({
    required this.text,
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
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Daily calorie norm.
// ---------------------------------------------------------------------------
class _CaloriesBlock extends StatelessWidget {
  final String value;
  final String unitLabel;
  final String unitTrailing;

  const _CaloriesBlock({
    required this.value,
    required this.unitLabel,
    required this.unitTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          unitLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              height: 1.0,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unitTrailing,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Macros — 3 columns: icon + value + g + label.
// ---------------------------------------------------------------------------
class _MacrosRow extends StatelessWidget {
  final int proteinG;
  final int fatG;
  final int carbsG;
  final String gramsUnit;
  final String proteinLabel;
  final String fatLabel;
  final String carbsLabel;

  const _MacrosRow({
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.gramsUnit,
    required this.proteinLabel,
    required this.fatLabel,
    required this.carbsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MacroColumn(
          icon: Icons.fitness_center,
          color: AppColors.blue,
          grams: proteinG,
          gramsUnit: gramsUnit,
          label: proteinLabel,
        ),
        _MacroColumn(
          icon: Icons.opacity,
          color: AppColors.orange,
          grams: fatG,
          gramsUnit: gramsUnit,
          label: fatLabel,
        ),
        _MacroColumn(
          icon: Icons.grain,
          color: AppColors.green,
          grams: carbsG,
          gramsUnit: gramsUnit,
          label: carbsLabel,
        ),
      ],
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int grams;
  final String gramsUnit;
  final String label;

  const _MacroColumn({
    required this.icon,
    required this.color,
    required this.grams,
    required this.gramsUnit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$grams',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              gramsUnit,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Psychotype card.
// ---------------------------------------------------------------------------
class _PsychotypeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isDark;

  const _PsychotypeCard({
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isDark
        ? AppColors.darkSurface2
        : AppColors.lightSurface2;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.resultPsychotypeLabel(title),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 18 / 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. "Your plan takes into account" — obstacles list.
// ---------------------------------------------------------------------------
class _ObstaclesBlock extends StatelessWidget {
  final List<String> labels;

  const _ObstaclesBlock({required this.labels});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.resultObstaclesHeader,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        for (final label in labels) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Milestone preview — week-by-week progress bars (lose/gain only).
// ---------------------------------------------------------------------------
class _MilestonesCard extends StatelessWidget {
  final List<({int week, double weight, DateTime date})> milestones;
  final double startWeight;
  final double targetWeight;
  final String Function(double) formatWeight;
  final Color cardBg;
  final Color lineColor;
  final bool isDark;

  const _MilestonesCard({
    required this.milestones,
    required this.startWeight,
    required this.targetWeight,
    required this.formatWeight,
    required this.cardBg,
    required this.lineColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Bar lengths are proportional to remaining distance from the target.
    final span = (startWeight - targetWeight).abs();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(_ResultStepState._cardRadius),
        border: Border.all(color: lineColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.resultMilestonesHeader,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < milestones.length; i++) ...[
            _MilestoneRow(
              week: milestones[i].week,
              weight: milestones[i].weight,
              startWeight: startWeight,
              targetWeight: targetWeight,
              span: span,
              isFinal: i == milestones.length - 1 &&
                  milestones[i].weight == targetWeight,
              formatWeight: formatWeight,
            ),
            if (i != milestones.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final int week;
  final double weight;
  final double startWeight;
  final double targetWeight;
  final double span;
  final bool isFinal;
  final String Function(double) formatWeight;

  const _MilestoneRow({
    required this.week,
    required this.weight,
    required this.startWeight,
    required this.targetWeight,
    required this.span,
    required this.isFinal,
    required this.formatWeight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = span > 0
        ? ((startWeight - weight).abs() / span).clamp(0.0, 1.0)
        : 0.0;
    // Bar shortens as the user approaches the target (visual countdown).
    final widthFactor = (1 - progress).clamp(0.08, 1.0);
    final barColor = isFinal ? AppColors.green : AppColors.primary;
    final labelText = isFinal
        ? context.l10n.resultGoalRow
        : context.l10n.resultWeekRow(week);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            labelText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isFinal ? FontWeight.w700 : FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(50),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: widthFactor,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            formatWeight(weight),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Methodology block — kept for App Store guideline 1.4.1 (citations for
// in-app health/medical calculations).
// ---------------------------------------------------------------------------
class _MethodologyBlock extends StatelessWidget {
  final String disclaimerLabel;
  final String disclaimerText;
  final String sourcesLabel;
  final VoidCallback onSourcesTap;

  const _MethodologyBlock({
    required this.disclaimerLabel,
    required this.disclaimerText,
    required this.sourcesLabel,
    required this.onSourcesTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant.withAlpha(145),
      height: 1.28,
    );
    final bodyStyle = TextStyle(
      fontSize: 10,
      color: cs.onSurfaceVariant.withAlpha(135),
      height: 1.26,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$disclaimerLabel — ', style: labelStyle),
              TextSpan(text: disclaimerText, style: bodyStyle),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _SourcesLink(label: sourcesLabel, onTap: onSourcesTap),
      ],
    );
  }
}

class _SourcesLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SourcesLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 13, color: linkColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: linkColor,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 13, color: linkColor),
          ],
        ),
      ),
    );
  }
}
