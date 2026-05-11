class TdeeCalculator {
  static const double _kcalPerKgFat = 7700;
  static const double _gainSafetyFactor = 0.6;

  static Map<String, double> calculate({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required double activityMultiplier,
    required String goal,
    required double weightLossKgPerWeek,
  }) {
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    double tdee = bmr * activityMultiplier;

    double dailyKcalDelta;
    switch (goal) {
      case 'lose':
        dailyKcalDelta = -(weightLossKgPerWeek * _kcalPerKgFat / 7);
      case 'gain':
        dailyKcalDelta =
            (weightLossKgPerWeek * _kcalPerKgFat / 7) * _gainSafetyFactor;
      default:
        dailyKcalDelta = 0;
    }

    double calorieGoal = (tdee + dailyKcalDelta).clamp(1200, 5000);

    return {
      'calories': calorieGoal.roundToDouble(),
      'protein': ((calorieGoal * 0.30) / 4).roundToDouble(),
      'fat': ((calorieGoal * 0.25) / 9).roundToDouble(),
      'carbs': ((calorieGoal * 0.45) / 4).roundToDouble(),
    };
  }

  static DateTime estimateTargetDate({
    required double currentWeight,
    required double targetWeight,
    required String goal,
    required double weightLossKgPerWeek,
  }) {
    final diff = (currentWeight - targetWeight).abs();
    if (goal == 'maintain' || weightLossKgPerWeek <= 0) {
      return DateTime.now();
    }
    final weeks = (diff / weightLossKgPerWeek).ceil();
    return DateTime.now().add(Duration(days: weeks * 7));
  }

  static List<({int week, double weight, DateTime date})> generateMilestones({
    required double currentWeight,
    required double targetWeight,
    required double weightLossKgPerWeek,
    required String goal,
    int maxWeeks = 6,
  }) {
    if (goal == 'maintain' || weightLossKgPerWeek <= 0) return const [];

    final direction = goal == 'lose' ? -1 : 1;
    final totalWeeks =
        ((currentWeight - targetWeight).abs() / weightLossKgPerWeek).ceil();
    if (totalWeeks <= 0) return const [];

    final stepsToShow =
        totalWeeks < maxWeeks ? totalWeeks : maxWeeks - 1;

    final milestones = <({int week, double weight, DateTime date})>[];
    final now = DateTime.now();
    for (int i = 1; i <= stepsToShow; i++) {
      final weight = currentWeight + (direction * weightLossKgPerWeek * i);
      final date = now.add(Duration(days: i * 7));
      milestones.add((week: i, weight: weight, date: date));
    }

    if (totalWeeks > maxWeeks - 1) {
      final finalDate = now.add(Duration(days: totalWeeks * 7));
      milestones.add(
        (week: totalWeeks, weight: targetWeight, date: finalDate),
      );
    }

    return milestones;
  }
}
