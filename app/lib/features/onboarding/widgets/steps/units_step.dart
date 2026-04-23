import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class UnitsStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const UnitsStep({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            context.l10n.onboardingUnitsTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingUnitsHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _UnitCard(
            title: context.l10n.unitsMetricTitle,
            subtitle: context.l10n.unitsMetricExamples,
            isSelected: selected == 'metric',
            onTap: () => onChanged('metric'),
          ),
          const SizedBox(height: 12),
          _UnitCard(
            title: context.l10n.unitsImperialTitle,
            subtitle: context.l10n.unitsImperialExamples,
            isSelected: selected == 'imperial',
            onTap: () => onChanged('imperial'),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitCard({
    required this.title,
    required this.subtitle,
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
        scale: isSelected ? 1.0 : 0.95,
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
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' ($subtitle)',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
