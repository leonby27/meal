import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';

class BehavioralQuizStep extends StatelessWidget {
  final Map<String, int> scores;
  final ValueChanged<Map<String, int>> onChanged;

  const BehavioralQuizStep({
    super.key,
    required this.scores,
    required this.onChanged,
  });

  static const List<String> _keys = [
    'stress_eating',
    'sweet_preference',
    'exercise_consistency',
    'meal_planning',
    'motivation_type',
  ];

  ({String left, String right}) _endpointsFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'stress_eating':
        return (left: l10n.quizStressEatingLeft, right: l10n.quizStressEatingRight);
      case 'sweet_preference':
        return (left: l10n.quizSweetPreferenceLeft, right: l10n.quizSweetPreferenceRight);
      case 'exercise_consistency':
        return (
          left: l10n.quizExerciseConsistencyLeft,
          right: l10n.quizExerciseConsistencyRight,
        );
      case 'meal_planning':
        return (left: l10n.quizMealPlanningLeft, right: l10n.quizMealPlanningRight);
      case 'motivation_type':
        return (left: l10n.quizMotivationTypeLeft, right: l10n.quizMotivationTypeRight);
    }
    return (left: '', right: '');
  }

  int _valueFor(String key) => scores[key] ?? 50;

  void _setValue(String key, int value) {
    final next = Map<String, int>.from(scores);
    next[key] = value;
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
          const SizedBox(height: 16),
          Text(
            l10n.onbQuizTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onbQuizHint,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          for (final key in _keys) ...[
            _QuizSlider(
              left: _endpointsFor(l10n, key).left,
              right: _endpointsFor(l10n, key).right,
              value: _valueFor(key),
              onChanged: (v) => _setValue(key, v),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _QuizSlider extends StatelessWidget {
  final String left;
  final String right;
  final int value;
  final ValueChanged<int> onChanged;

  const _QuizSlider({
    required this.left,
    required this.right,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? AppColors.lineDT300
        : AppColors.lineLight300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, AppColors.orange],
                    ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withAlpha(40),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 100,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      onChanged(v.round());
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                left,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                right,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
