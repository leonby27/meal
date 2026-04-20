import 'dart:math' as math;

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
    final proteinPct = totalGrams > 0 ? ((protein / totalGrams) * 100).round() : 0;
    final fatPct = totalGrams > 0 ? ((fat / totalGrams) * 100).round() : 0;
    final carbsPct = totalGrams > 0 ? ((carbs / totalGrams) * 100).round() : 0;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // --- Section 1: Title ---
          Text(
            context.l10n.resultCongratsTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.resultCongratsSubtitle,
            style: TextStyle(
              fontSize: 16,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // --- Section 2: Macro ring with labels ---
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
                          proteinFraction: totalGrams > 0 ? protein / totalGrams : 0.33,
                          fatFraction: totalGrams > 0 ? fat / totalGrams : 0.33,
                          carbsFraction: totalGrams > 0 ? carbs / totalGrams : 0.34,
                          progress: p,
                          bgColor: cs.outline.withAlpha(30),
                        ),
                      ),
                    ),
                    // Center text
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
                    // Macro labels around the ring
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
          const SizedBox(height: 20),

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

          // --- Section 3: Can change ---
          Text(
            context.l10n.resultCanChange,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // --- Section 4: How to reach goals ---
          Text(
            context.l10n.resultHowToTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _TipCard(
            icon: Icons.restaurant_menu,
            iconColor: AppColors.orange,
            text: context.l10n.resultTip1,
            cardBg: cardBg,
            lineColor: lineColor,
          ),
          const SizedBox(height: 10),
          _TipCard(
            icon: Icons.local_fire_department,
            iconColor: AppColors.sepia,
            text: context.l10n.resultTip2,
            cardBg: cardBg,
            lineColor: lineColor,
          ),
          const SizedBox(height: 10),
          _TipCard(
            icon: Icons.pie_chart_outline,
            iconColor: AppColors.purple,
            text: context.l10n.resultTip3,
            cardBg: cardBg,
            lineColor: lineColor,
          ),
          const SizedBox(height: 36),

          // --- Section 5: Improvements ---
          Text(
            context.l10n.resultImprovementsTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.resultImprovementsBody,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // --- Section 6: Disclaimer ---
          Text(
            context.l10n.resultDisclaimer,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withAlpha(150),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
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

  String _formatCalories(int cal) {
    if (cal >= 1000) {
      final whole = cal ~/ 1000;
      final rest = cal % 1000;
      if (rest == 0) return '$whole 000';
      return '$whole ${rest.toString().padLeft(3, '0')}';
    }
    return '$cal';
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

    // Background ring
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
// Small widgets
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

class _TipCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color cardBg;
  final Color lineColor;

  const _TipCard({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.cardBg,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
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
