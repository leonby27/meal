import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';

/// "What do you want to improve?" — multi-select step with emoji icons
/// per option. Pattern mirrors [ObstaclesStep].
class ImproveGoalsStep extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const ImproveGoalsStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<({String value, String emoji})> _options = [
    (value: 'look_better', emoji: 'star-struck'),
    (value: 'feel_confident', emoji: 'smirking-face'),
    (value: 'improve_health', emoji: 'four-leaf-clover'),
    (value: 'more_energy', emoji: 'battery'),
    (value: 'less_stress', emoji: 'hot-beverage'),
    (value: 'immunity', emoji: 'oncoming-fist'),
    (value: 'focus', emoji: 'brain'),
    (value: 'sleep', emoji: 'sleeping-face'),
  ];

  static String labelFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'look_better':
        return l10n.onbImproveLookBetter;
      case 'feel_confident':
        return l10n.onbImproveFeelConfident;
      case 'improve_health':
        return l10n.onbImproveHealth;
      case 'more_energy':
        return l10n.onbImproveMoreEnergy;
      case 'less_stress':
        return l10n.onbImproveLessStress;
      case 'immunity':
        return l10n.onbImproveImmunity;
      case 'focus':
        return l10n.onbImproveFocus;
      case 'sleep':
        return l10n.onbImproveSleep;
    }
    return key;
  }

  void _toggle(String value) {
    final next = Set<String>.from(selected);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            l10n.onbImproveTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          for (final option in _options) ...[
            _ImproveCard(
              label: labelFor(l10n, option.value),
              emoji: option.emoji,
              isSelected: selected.contains(option.value),
              onTap: () => _toggle(option.value),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ImproveCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImproveCard({
    required this.label,
    required this.emoji,
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
        scale: isSelected ? 1.0 : 0.98,
        duration: const Duration(milliseconds: 180),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              NotoEmoji(name: emoji, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
