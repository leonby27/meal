import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// "Trial period will soon end" reminder shown right after the personal
/// plan. The bottom panel (check line, CTA, yearly/monthly subtitle) is
/// rendered by [OnboardingFlow] so it stays mounted across the
/// result → trial-reminder transition; this widget only paints the
/// hero copy and the bell illustration.
class TrialReminderStep extends StatelessWidget {
  const TrialReminderStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            l10n.onbTrialReminderTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
          const Spacer(),
          // Bell hero illustration. Source is 1240x1240 @4.0x.
          SizedBox(
            width: 196,
            height: 196,
            child: Image.asset(
              'assets/onboarding/bell.jpg',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
