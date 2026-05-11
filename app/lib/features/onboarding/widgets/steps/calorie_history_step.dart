import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// "Have you ever counted calories?" — single-select option step shown
/// after the gender step. The "tried but gave up" option uses an ARB
/// `{gender, select, …}` placeholder so Russian renders the correct
/// past-tense verb form for the speaker's gender.
class CalorieHistoryStep extends StatelessWidget {
  final String? selected;
  final String? gender;
  final ValueChanged<String> onChanged;

  const CalorieHistoryStep({
    super.key,
    required this.selected,
    required this.gender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Gender token must be 'male' / 'female' / anything (falls back to
    // the `other` branch). The data model uses these exact tokens.
    final genderToken = gender ?? 'other';

    final options = [
      (l10n.onbCalorieHistoryYes, 'yes_still'),
      (l10n.onbCalorieHistoryTried(genderToken), 'tried_quit'),
      (l10n.onbCalorieHistoryNever, 'never'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            l10n.onbCalorieHistoryTitle,
            style: onboardingTitleStyle(context),
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
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.97,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : lineColor,
              width: isSelected ? 1.5 : 1,
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
