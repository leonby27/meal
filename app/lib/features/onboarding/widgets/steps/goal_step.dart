import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            context.l10n.onboardingGoalTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
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
          const SizedBox(height: 32),
          for (final (label, value) in options) ...[
            _OptionCard(
              label: label,
              isSelected: selected == value,
              onTap: () => onChanged(value),
            ),
            const SizedBox(height: 12),
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
          height: 72,
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : lineColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: AnimatedScale(
                scale: isSelected ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 32),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
