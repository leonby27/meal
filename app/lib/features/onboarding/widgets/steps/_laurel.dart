import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Side of the body the branch grows from.
enum LaurelSide { left, right }

/// A single laurel branch — half of a wreath.
///
/// Used to bracket a hero number/title so the screen reads as
/// "achievement" / "premium" instead of "tap me". Two branches
/// (left + right) compose into the open wreath you see in Cal AI's
/// onboarding.
///
/// Curves outward from the bottom and up, with leaves staggered
/// alternately on either side of the stem to look natural.
class LaurelBranch extends StatelessWidget {
  final LaurelSide side;
  final double width;
  final double height;
  final Color color;

  const LaurelBranch({
    super.key,
    required this.side,
    required this.color,
    this.width = 64,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _LaurelBranchPainter(side: side, color: color),
      ),
    );
  }
}

class _LaurelBranchPainter extends CustomPainter {
  final LaurelSide side;
  final Color color;

  _LaurelBranchPainter({required this.side, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final isLeft = side == LaurelSide.left;

    // Mirror the canvas so we only need to draw one orientation.
    if (isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Stem path — curves up and slightly inward, mimicking a
    // laurel half-wreath that opens toward the center of the screen.
    final stemPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.95)
      ..cubicTo(
        size.width * 0.65, size.height * 0.85,
        size.width * 0.95, size.height * 0.55,
        size.width * 0.55, size.height * 0.05,
      );

    // Draw a thin stem line
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(stemPath, stemPaint);

    // Place leaves along the stem path. Alternating sides + slight
    // size variation give the branch a natural, hand-drawn feel.
    final metrics = stemPath.computeMetrics().first;
    const leafCount = 9;

    for (var i = 0; i < leafCount; i++) {
      // Skip the very tip and the very base for cleaner ends.
      final t = 0.06 + (i / (leafCount - 1)) * 0.88;
      final tangent = metrics.getTangentForOffset(metrics.length * t);
      if (tangent == null) continue;

      final pos = tangent.position;
      // Tangent direction along the stem
      final dirAngle = math.atan2(tangent.vector.dy, tangent.vector.dx);

      // Alternate leaf side around the stem
      final outward = i.isEven ? -1.0 : 1.0;
      // Leaf sticks out perpendicular to the stem
      final leafAngle = dirAngle + outward * (math.pi / 2 - 0.25);

      // Outer leaves slightly smaller; mid-branch leaves largest
      final scaleCurve = math.sin(t * math.pi);
      final scale = 0.75 + 0.45 * scaleCurve;

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(leafAngle);
      _drawLeaf(canvas, paint, scale);
      canvas.restore();
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, double scale) {
    // Almond-shaped leaf, tip pointing along +y in local space.
    final w = 7.0 * scale;
    final h = 18.0 * scale;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(w, h * 0.35, w * 0.25, h)
      ..quadraticBezierTo(0, h + 1.5, -w * 0.25, h)
      ..quadraticBezierTo(-w, h * 0.35, 0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LaurelBranchPainter old) =>
      old.color != color || old.side != side;
}

/// Hero "trophy-style" stat: two laurel branches bracketing a big
/// centered value with a small caption beneath.
///
/// Mirrors the visual language used by Cal AI / Lose It! / Yazio
/// during their social-proof onboarding screens.
class LaurelStat extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final double valueFontSize;

  const LaurelStat({
    super.key,
    required this.value,
    required this.label,
    required this.accent,
    this.valueFontSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LaurelBranch(side: LaurelSide.left, color: accent),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.05,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        LaurelBranch(side: LaurelSide.right, color: accent),
      ],
    );
  }
}
