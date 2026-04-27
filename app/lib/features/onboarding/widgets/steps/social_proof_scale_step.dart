import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_laurel.dart';

/// Social proof — Step 1 of 3: scale & technology.
///
/// "Trophy"-style screen: two hero stats (database size + recognition
/// speed), each bracketed by laurel branches. Reads as an award/badge
/// rather than a list of clickable cards. Closes with a "Powered by
/// OpenAI" pill that sits clearly outside the trophy area.
class SocialProofScaleStep extends StatefulWidget {
  const SocialProofScaleStep({super.key});

  @override
  State<SocialProofScaleStep> createState() => _SocialProofScaleStepState();
}

class _SocialProofScaleStepState extends State<SocialProofScaleStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
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

    final headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    final stat1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
      ),
    );

    final stat2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    final badgeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          FadeTransition(
            opacity: headerFade,
            child: Column(
              children: [
                Text(
                  context.l10n.socialProofScaleTitle,
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
                  context.l10n.socialProofScaleSubtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Hero stat 1 — products count, with laurels on each side
          FadeTransition(
            opacity: stat1Fade,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final p = _animation.value;
                final value = (3000000 * p).round();
                return LaurelStat(
                  accent: AppColors.primary,
                  value: '${_formatThousands(value)}+',
                  label: context.l10n.socialProofScaleProductsLabel,
                  valueFontSize: 32,
                );
              },
            ),
          ),
          const SizedBox(height: 36),

          // Hero stat 2 — recognition speed
          FadeTransition(
            opacity: stat2Fade,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final p = _animation.value;
                final value = (5 * p).clamp(0.0, 5.0);
                return LaurelStat(
                  accent: AppColors.primary,
                  value:
                      '< ${value.toStringAsFixed(0)} ${context.l10n.socialProofScaleSecondsUnit}',
                  label: context.l10n.socialProofScaleSpeedLabel,
                  valueFontSize: 36,
                );
              },
            ),
          ),
          const SizedBox(height: 48),

          // Powered by OpenAI badge
          FadeTransition(
            opacity: badgeFade,
            child: _PoweredByBadge(isDark: isDark),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Formats `3000000` → `3 000 000` with non-breaking spaces.
  String _formatThousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00A0');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ---------------------------------------------------------------------------
// "Powered by OpenAI" pill
// ---------------------------------------------------------------------------
class _PoweredByBadge extends StatelessWidget {
  final bool isDark;

  const _PoweredByBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final lineColor = isDark ? AppColors.lineDT200 : AppColors.lineLight200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: lineColor),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      foregroundDecoration: AppTheme.cardEdgeForeground(
        isDark: isDark,
        radius: 100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CustomPaint(
              painter: _OpenAiMarkPainter(color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.socialProofPoweredBy,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'OpenAI',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stylized hex-flower mark — abstract enough to read as a "tech"
/// logo without infringing the OpenAI trademark.
class _OpenAiMarkPainter extends CustomPainter {
  final Color color;

  _OpenAiMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < 6; i++) {
      final angle = (math.pi * 2 / 6) * i - math.pi / 2;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * radius * 0.45,
        center.dy + math.sin(angle) * radius * 0.45,
      );
      canvas.drawCircle(petalCenter, radius * 0.55, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OpenAiMarkPainter old) => old.color != color;
}
