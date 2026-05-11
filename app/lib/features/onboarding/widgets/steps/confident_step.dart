import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// Trust / privacy onboarding screen.
///
/// Layout: image + text block is optically centred in the empty space
/// between header and privacy card; the privacy card sits just above
/// the parent's floating CTA. Uses two [Spacer]s, which is the same
/// pattern as `target_weight_step` / `age_step` (both work fine in
/// AnimatedSwitcher transitions).
class ConfidentStep extends StatelessWidget {
  const ConfidentStep({super.key});

  // Hero photo logical dimensions (matches the 4.0x asset and the
  // Figma rect).
  static const double _heroWidth = 286;
  static const double _heroHeight = 256;

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
              'assets/onboarding/trust_hands.jpg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onbConfidentTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onbConfidentSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          const _PrivacyCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/onboarding/icons/confident.svg',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.onbConfidentPrivacyTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.onbConfidentPrivacyBody,
                  style: TextStyle(
                    fontSize: 12,
                    height: 14 / 12,
                    color: cs.onSurface.withAlpha(160),
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
