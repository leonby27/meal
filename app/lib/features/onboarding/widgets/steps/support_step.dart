import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// "We're with you all the way" — emotional support card shown right
/// before the age step. Hero illustration swaps between man and woman
/// based on the gender chosen earlier in the funnel; falls back to the
/// woman shot if gender is null.
class SupportStep extends StatelessWidget {
  final String? gender;

  const SupportStep({super.key, required this.gender});

  // Hero illustration logical dimensions. The source assets are
  // 1184×1460 at 4.0x — i.e. 296×365 pt — but we cap the height a bit
  // to leave breathing room for the text block below.
  static const double _heroWidth = 280;
  static const double _heroHeight = 320;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final asset = gender == 'male'
        ? 'assets/onboarding/support_man.jpg'
        : 'assets/onboarding/support_woman.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          SizedBox(
            width: _heroWidth,
            height: _heroHeight,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onbSupportTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onbSupportSubtitle,
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
