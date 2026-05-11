import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

class ActivityStep extends StatelessWidget {
  final double? selected;
  final ValueChanged<double> onChanged;

  const ActivityStep({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = [
      (context.l10n.activitySedentary, 1.2, 'couch-and-lamp'),
      (context.l10n.activityLight, 1.375, 'person-walking'),
      (context.l10n.activityModerate, 1.55, 'person-running'),
      (context.l10n.activityHigh, 1.725, 'fire'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            context.l10n.onboardingActivityTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingActivityHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          for (final (title, value, emoji) in options) ...[
            _ActivityCard(
              title: title,
              emoji: emoji,
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

class _ActivityCard extends StatelessWidget {
  final String title;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            NotoEmoji(name: emoji, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
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
