import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// Social-proof / efficacy pitch shown right after the weight-loss
/// speed slider. A two-bar comparison illustration ("Going Solo" vs
/// "With BodyMeal x2") plus a marketing line that "people lose weight
/// faster with support". Same layout pattern as [SupportStep] /
/// [KeepResultStep].
class SocialProofStep extends StatelessWidget {
  const SocialProofStep({super.key});

  // Source asset is 880×920 at 4.0x → 220×230 pt. We render a touch
  // larger than intrinsic so the bars feel weighty.
  static const double _heroWidth = 260;
  static const double _heroHeight = 272;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          SizedBox(
            width: _heroWidth,
            height: _heroHeight,
            child: Image.asset(
              'assets/onboarding/compare.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onbSocialProofTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onbSocialProofSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
