class OnboardingData {
  String? goal = 'lose';
  String? gender = 'female';
  int age = 26;
  String unitSystem = 'metric';
  double heightCm = 170;
  double weightKg = 70.0;
  double targetWeightKg = 65.0;
  double activityMultiplier = 1.375;

  bool get isImperial => unitSystem == 'imperial';

  double? calorieGoal;
  double? proteinGoal;
  double? fatGoal;
  double? carbsGoal;
  DateTime? targetDate;
}
