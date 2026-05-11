import 'package:flutter/material.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';

class ObstaclesStep extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const ObstaclesStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Stable identifiers + emoji glyph; the user-facing label is resolved
  /// from the localized arb at render time via [_labelFor]. Emojis are
  /// rendered with the system color font (Apple Color Emoji on iOS,
  /// Noto Color Emoji on Android).
  /// Each option maps to a Noto SVG bundled under
  /// `assets/onboarding/emoji/` (file name == [emoji] + `.svg`).
  static const List<({String value, String emoji})> _options = [
    (value: 'consistency', emoji: 'counterclockwise-arrows-button'),
    (value: 'knowledge', emoji: 'thinking-face'),
    (value: 'busy', emoji: 'alarm-clock'),
    (value: 'cravings', emoji: 'doughnut'),
    (value: 'support', emoji: 'people-hugging'),
    (value: 'eating_out', emoji: 'fork-and-knife-with-plate'),
    (value: 'motivation', emoji: 'high-voltage'),
    (value: 'tracking', emoji: 'abacus'),
  ];

  /// Locale-aware label lookup used by ResultStep to render the user's
  /// chosen obstacles in the "plan accounts for" block.
  static String? labelFor(AppLocalizations l10n, String key) {
    return _labelFor(l10n, key);
  }

  static String _labelFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'consistency':
        return l10n.obstacleConsistency;
      case 'knowledge':
        return l10n.obstacleKnowledge;
      case 'busy':
        return l10n.obstacleBusy;
      case 'cravings':
        return l10n.obstacleCravings;
      case 'support':
        return l10n.obstacleSupport;
      case 'eating_out':
        return l10n.obstacleEatingOut;
      case 'motivation':
        return l10n.obstacleMotivation;
      case 'tracking':
        return l10n.obstacleTracking;
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
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          Text(
            l10n.onbObstaclesTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onbObstaclesHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          for (final option in _options) ...[
            _ObstacleCard(
              label: _labelFor(l10n, option.value),
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

class _ObstacleCard extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ObstacleCard({
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
                    height: 18 / 14,
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
