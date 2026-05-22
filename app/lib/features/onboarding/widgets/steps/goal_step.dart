import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

class GoalStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const GoalStep({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = [
      (context.l10n.goalLoseWeight, 'lose'),
      (context.l10n.goalMaintainWeight, 'maintain'),
      (context.l10n.goalGainWeight, 'gain'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            context.l10n.onboardingGoalTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingGoalHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          for (final (label, value) in options) ...[
            _OptionCard(
              label: label,
              isSelected: selected == value,
              onTap: () => onChanged(value),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.onboardingClickableBg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.97,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.onboardingCtaBg
                  : Colors.transparent,
              width: 2,
            ),
          ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        ),
      ),
    );
  }
}
