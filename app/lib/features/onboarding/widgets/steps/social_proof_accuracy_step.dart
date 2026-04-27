import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_laurel.dart';

/// Social proof — Step 2 of 3: AI accuracy.
///
/// Headline figure (92%) bracketed by laurel branches with a row of
/// 5 popping-in stars overhead. Final small disclaimer line below
/// keeps the credibility ("based on internal QA on 500+ dishes")
/// without breaking the trophy aesthetic.
class SocialProofAccuracyStep extends StatefulWidget {
  const SocialProofAccuracyStep({super.key});

  @override
  State<SocialProofAccuracyStep> createState() =>
      _SocialProofAccuracyStepState();
}

class _SocialProofAccuracyStepState extends State<SocialProofAccuracyStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _starsAnim;
  late final Animation<double> _percentAnim;

  static const _targetPercent = 92;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _starsAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _percentAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
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

    final headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    final disclaimerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
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
                  context.l10n.socialProofAccuracyTitle,
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
                  context.l10n.socialProofAccuracySubtitle,
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
          const SizedBox(height: 36),

          _AnimatedStarRow(animation: _starsAnim),
          const SizedBox(height: 18),

          // 92% bracketed by laurels
          AnimatedBuilder(
            animation: _percentAnim,
            builder: (context, _) {
              final value = (_targetPercent * _percentAnim.value).round();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  LaurelBranch(
                    side: LaurelSide.left,
                    color: AppColors.primary,
                    width: 80,
                    height: 150,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$value',
                              style: TextStyle(
                                fontSize: 84,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                height: 1.0,
                                letterSpacing: -3,
                              ),
                            ),
                            TextSpan(
                              text: '%',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.socialProofAccuracyLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  LaurelBranch(
                    side: LaurelSide.right,
                    color: AppColors.primary,
                    width: 80,
                    height: 150,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          FadeTransition(
            opacity: disclaimerFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.l10n.socialProofAccuracyDisclaimer,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withAlpha(180),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated 5-star row. Stars pop in with a small staggered delay.
// ---------------------------------------------------------------------------
class _AnimatedStarRow extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedStarRow({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final start = i * 0.12;
            final localT = ((animation.value - start) / (1.0 - start))
                .clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: 0.5 + 0.5 * localT,
                child: Opacity(
                  opacity: localT,
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB800),
                    size: 40,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
