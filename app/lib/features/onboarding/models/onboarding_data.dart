class OnboardingData {
  String? goal = 'lose';
  String? gender = 'female';
  int age = 26;
  String unitSystem = 'metric';
  double heightCm = 170;
  double weightKg = 70.0;
  double targetWeightKg = 65.0;
  double activityMultiplier = 1.375;

  Set<String> obstacles = <String>{};
  double weightLossKgPerWeek = 0.5;
  Map<String, int> behavioralScores = <String, int>{};
  String? psychotype;
  String? calorieHistory; // 'tried_quit' / 'yes_still' / 'never'
  Set<String> improveGoals = <String>{}; // multi-select
  String? eatingObstacle; // single-select
  String? hardestChallenge; // single-select

  bool get isImperial => unitSystem == 'imperial';

  double? calorieGoal;
  double? proteinGoal;
  double? fatGoal;
  double? carbsGoal;
  DateTime? targetDate;

  /// Number of meaningful onboarding answers used to build the plan.
  /// Shown on the plan-reveal card as "Tailored from your {n} answers".
  int get answeredCount {
    var n = 8; // goal, gender, age, units, height, weight, target weight, activity
    if (obstacles.isNotEmpty) n++;
    if (weightLossKgPerWeek > 0 && goal != 'maintain') n++;
    if (psychotype != null) n++;
    if (calorieHistory != null) n++;
    if (improveGoals.isNotEmpty) n++;
    if (eatingObstacle != null) n++;
    if (hardestChallenge != null) n++;
    return n;
  }
}
