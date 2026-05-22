import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

class GenderStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const GenderStep({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            context.l10n.onboardingGenderTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingGenderHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  label: context.l10n.genderMale,
                  isSelected: selected == 'male',
                  onTap: () => onChanged('male'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GenderCard(
                  label: context.l10n.genderFemale,
                  isSelected: selected == 'female',
                  onTap: () => onChanged('female'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
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
          alignment: Alignment.center,
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
          child: Text(
            label,
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
