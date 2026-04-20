class TdeeCalculator {
  static Map<String, double> calculate({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required double activityMultiplier,
    required String goal,
  }) {
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    double tdee = bmr * activityMultiplier;

    double calorieGoal;
    switch (goal) {
      case 'lose':
        calorieGoal = tdee - 500;
      case 'gain':
        calorieGoal = tdee + 300;
      default:
        calorieGoal = tdee;
    }

    calorieGoal = calorieGoal.clamp(1200, 5000);

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
  }) {
    double diff = (currentWeight - targetWeight).abs();
    double weeklyRate = goal == 'lose' ? 0.5 : goal == 'gain' ? 0.25 : 0;
    int weeks = weeklyRate > 0 ? (diff / weeklyRate).ceil() : 0;
    return DateTime.now().add(Duration(days: weeks * 7));
  }
}
