import 'package:meal_tracker/l10n/app_localizations.dart';

class PsychotypeInfo {
  final String key;
  final String title;
  final String description;

  const PsychotypeInfo({
    required this.key,
    required this.title,
    required this.description,
  });
}

class Psychotype {
  static const _quizKeys = [
    'stress_eating',
    'sweet_preference',
    'exercise_consistency',
    'meal_planning',
    'motivation_type',
  ];

  static List<String> get quizKeys => _quizKeys;

  /// Locale-aware lookup of the user-facing copy for a psychotype key.
  /// Falls back to 'balanced' for unknown / null keys so the UI never
  /// renders an empty card.
  static PsychotypeInfo infoFor(AppLocalizations l10n, String? key) {
    switch (key) {
      case 'stress_eater':
        return PsychotypeInfo(
          key: 'stress_eater',
          title: l10n.psyStressEaterTitle,
          description: l10n.psyStressEaterDesc,
        );
      case 'fuel_focused':
        return PsychotypeInfo(
          key: 'fuel_focused',
          title: l10n.psyFuelFocusedTitle,
          description: l10n.psyFuelFocusedDesc,
        );
      case 'sweet_lover':
        return PsychotypeInfo(
          key: 'sweet_lover',
          title: l10n.psySweetLoverTitle,
          description: l10n.psySweetLoverDesc,
        );
      case 'savory_lover':
        return PsychotypeInfo(
          key: 'savory_lover',
          title: l10n.psySavoryLoverTitle,
          description: l10n.psySavoryLoverDesc,
        );
      case 'consistent_athlete':
        return PsychotypeInfo(
          key: 'consistent_athlete',
          title: l10n.psyConsistentAthleteTitle,
          description: l10n.psyConsistentAthleteDesc,
        );
      case 'inconsistent':
        return PsychotypeInfo(
          key: 'inconsistent',
          title: l10n.psyInconsistentTitle,
          description: l10n.psyInconsistentDesc,
        );
      case 'planner':
        return PsychotypeInfo(
          key: 'planner',
          title: l10n.psyPlannerTitle,
          description: l10n.psyPlannerDesc,
        );
      case 'convenience_eater':
        return PsychotypeInfo(
          key: 'convenience_eater',
          title: l10n.psyConvenienceEaterTitle,
          description: l10n.psyConvenienceEaterDesc,
        );
      case 'results_driven':
        return PsychotypeInfo(
          key: 'results_driven',
          title: l10n.psyResultsDrivenTitle,
          description: l10n.psyResultsDrivenDesc,
        );
      case 'feelings_driven':
        return PsychotypeInfo(
          key: 'feelings_driven',
          title: l10n.psyFeelingsDrivenTitle,
          description: l10n.psyFeelingsDrivenDesc,
        );
      case 'balanced':
      default:
        return PsychotypeInfo(
          key: 'balanced',
          title: l10n.psyBalancedTitle,
          description: l10n.psyBalancedDesc,
        );
    }
  }

  /// Picks the slider with the largest deviation from 50 and maps the side
  /// (<50 = left, ≥50 = right) to a psychotype key. If all sliders sit
  /// within 25 of the centre, returns `balanced`.
  static String compute(Map<String, int> scores) {
    String? extremeKey;
    int maxDeviation = 0;
    scores.forEach((key, value) {
      final deviation = (value - 50).abs();
      if (deviation > maxDeviation) {
        maxDeviation = deviation;
        extremeKey = key;
      }
    });

    if (extremeKey == null || maxDeviation < 25) return 'balanced';

    final value = scores[extremeKey!]!;
    switch (extremeKey!) {
      case 'stress_eating':
        return value < 50 ? 'stress_eater' : 'fuel_focused';
      case 'sweet_preference':
        return value < 50 ? 'sweet_lover' : 'savory_lover';
      case 'exercise_consistency':
        return value < 50 ? 'consistent_athlete' : 'inconsistent';
      case 'meal_planning':
        return value < 50 ? 'planner' : 'convenience_eater';
      case 'motivation_type':
        return value < 50 ? 'results_driven' : 'feelings_driven';
      default:
        return 'balanced';
    }
  }
}
