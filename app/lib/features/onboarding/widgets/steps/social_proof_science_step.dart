import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

/// Social proof — Step 3 of 3: scientific basis.
///
/// Showcases the Mifflin-St Jeor formula as the engine behind the
/// personal calorie plan. This is the last screen before the paywall,
/// so it doubles as a final trust anchor: "your plan is built on real
/// nutrition science, not guesswork".
class SocialProofScienceStep extends StatefulWidget {
  const SocialProofScienceStep({super.key});

  @override
  State<SocialProofScienceStep> createState() =>
      _SocialProofScienceStepState();
}

class _SocialProofScienceStepState extends State<SocialProofScienceStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          Text(
            context.l10n.socialProofScienceTitle,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.socialProofScienceSubtitle,
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Hero medallion — laurel wreath around a trophy
          ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: _LaurelMedallion(isDark: isDark),
            ),
          ),
          const SizedBox(height: 28),

          // Formula name
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Mifflin-St Jeor',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.socialProofScienceFormulaCaption,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Trust card
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: _TrustCard(isDark: isDark),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Laurel medallion — laurel wreath painted around a centered trophy icon.
// ---------------------------------------------------------------------------
class _LaurelMedallion extends StatelessWidget {
  final bool isDark;

  const _LaurelMedallion({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft halo
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withAlpha(isDark ? 22 : 14),
            ),
          ),

          // Laurel wreath
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _LaurelWreathPainter(color: accent),
            ),
          ),

          // Inner medallion with trophy
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(
                color: accent.withAlpha(60),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withAlpha(isDark ? 30 : 20),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: accent,
              size: 64,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints two arcs of laurel leaves on the left and right sides,
/// curving up and meeting near the top, like a classic award badge.
class _LaurelWreathPainter extends CustomPainter {
  final Color color;

  _LaurelWreathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Each side has 9 leaves, angled outward, fanning from
    // the bottom of the wreath up to ~45° from vertical.
    const leavesPerSide = 9;
    const startAngle = math.pi * 0.5;  // bottom (pointing down)
    const endAngle = math.pi * 0.15;   // near top, slightly tilted in

    for (var side = 0; side < 2; side++) {
      final isLeft = side == 0;
      for (var i = 0; i < leavesPerSide; i++) {
        final t = i / (leavesPerSide - 1);
        // Angle around center (0 = right, pi/2 = bottom).
        final base = startAngle - (startAngle - endAngle) * t;
        final angle = isLeft ? math.pi - base : base;

        final leafCenter = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );

        // Leaf points outward-tangent-ish; rotate to look natural.
        final leafAngle = angle + math.pi / 2 + (isLeft ? -0.4 : 0.4);

        canvas.save();
        canvas.translate(leafCenter.dx, leafCenter.dy);
        canvas.rotate(leafAngle);
        // Tapered leaf — outer leaves slightly smaller.
        final scale = 1.0 - (i / leavesPerSide) * 0.25;
        _drawLeaf(canvas, fillPaint, scale);
        canvas.restore();
      }
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, double scale) {
    final w = 8.0 * scale;
    final h = 18.0 * scale;
    final path = Path()
      ..moveTo(0, -h / 2)
      ..quadraticBezierTo(w, -h / 4, w * 0.4, h / 2)
      ..quadraticBezierTo(0, h / 2 + 2, -w * 0.4, h / 2)
      ..quadraticBezierTo(-w, -h / 4, 0, -h / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LaurelWreathPainter old) =>
      old.color != color;
}

// ---------------------------------------------------------------------------
// Trust card — "used by dietitians worldwide".
// ---------------------------------------------------------------------------
class _TrustCard extends StatelessWidget {
  final bool isDark;

  const _TrustCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.green2.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.green2,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.socialProofScienceTrust,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
