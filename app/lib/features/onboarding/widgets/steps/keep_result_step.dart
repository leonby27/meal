import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// Retention pitch shown right after gender. A weight-curve chart
/// over time, with the marketing line "MealTracker helps you keep
/// results". Same layout pattern as `ConfidentStep` minus the
/// privacy card.
class KeepResultStep extends StatelessWidget {
  const KeepResultStep({super.key});

  // Chart asset's logical size (4.0x export: 1440 × 916 → 360 × 229 pt).
  // We render at the asset's native 1× point size — this lifts the chart
  // by ~12 % vs the previous 320 pt clamp without compressing the title
  // or subtitle slots underneath. The new headline ("Lose weight that
  // stays off.") is shorter than the prior retention copy so the extra
  // chart height fits comfortably even on a 4.7-inch device.
  static const double _heroWidth = 360;
  static const double _heroHeight = 229;

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
              'assets/onboarding/chart.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onbKeepResultTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onbKeepResultSubtitle,
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
