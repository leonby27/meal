import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/login_sync_service.dart';
import 'package:meal_tracker/features/onboarding/models/onboarding_data.dart';
import 'package:meal_tracker/features/onboarding/services/tdee_calculator.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/activity_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/age_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/calorie_history_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/confident_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/eating_obstacle_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/gender_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/goal_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/hardest_challenge_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/improve_goals_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/keep_result_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/height_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/loading_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/obstacles_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/rate_prompt_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/result_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/social_proof_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/support_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/target_weight_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/trial_reminder_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/units_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/welcome_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/weight_loss_speed_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/weight_step.dart';
// Social-proof steps are temporarily disabled — files kept on disk for
// when we return to polish them.
// import 'package:meal_tracker/features/onboarding/widgets/steps/social_proof_scale_step.dart';
// import 'package:meal_tracker/features/onboarding/widgets/steps/social_proof_accuracy_step.dart';

enum _StepKind {
  welcome,
  confident,
  goal,
  obstacles,
  gender,
  calorieHistory,
  keepResult,
  improveGoals,
  eatingObstacle,
  hardestChallenge,
  support,
  age,
  units,
  height,
  weight,
  targetWeight,
  weightLossSpeed,
  socialProof,
  activity,
  loading,
  result,
  trialReminder,
  ratePrompt,
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _data = OnboardingData();
  int _currentPage = 0;
  bool _activitySelected = true;
  bool _isForward = true;
  bool _isFinishing = false;
  bool _onboardingCompleted = false;
  String? _precachedStepImagesKey;
  int _backClicksCount = 0;
  DateTime _stepStartedAt = DateTime.now();
  final Stopwatch _onboardingStopwatch = Stopwatch();
  final Set<int> _stepsSeen = <int>{};

  static const _stepImageAspectRatio = 1024 / 632;
  static const _stepImageHorizontalPadding = 16.0;
  static const _stepImageBottomOffset = 84.0;
  static const _stepImageContentGap = 12.0;
  static const _ctaButtonHeight = 56.0;
  static const _ctaButtonBottomMargin = 16.0;

  // Mascot illustrations are hidden in the new onboarding flow. The PNG
  // assets are kept on disk so we can re-enable them by re-listing the
  // matching step kinds here.
  static const _imageOrderedKinds = <_StepKind>[];

  static const _darkStepImageAssets = [
    'assets/onboarding/dark/step_1.png',
    'assets/onboarding/dark/step_2.png',
    'assets/onboarding/dark/step_3.png',
    'assets/onboarding/dark/step_4.png',
    'assets/onboarding/dark/step_5.png',
    'assets/onboarding/dark/step_6.png',
    'assets/onboarding/dark/step_7.png',
    'assets/onboarding/dark/step_8.png',
  ];
  static const _lightStepImageAssets = [
    'assets/onboarding/light/step_1.png',
    'assets/onboarding/light/step_2.png',
    'assets/onboarding/light/step_3.png',
    'assets/onboarding/light/step_4.png',
    'assets/onboarding/light/step_5.png',
    'assets/onboarding/light/step_6.png',
    'assets/onboarding/light/step_7.png',
    'assets/onboarding/light/step_8.png',
  ];

  List<_StepKind> get _kinds {
    return [
      _StepKind.welcome,
      _StepKind.confident,
      _StepKind.goal,
      _StepKind.obstacles,
      _StepKind.gender,
      _StepKind.calorieHistory,
      _StepKind.keepResult,
      _StepKind.improveGoals,
      _StepKind.eatingObstacle,
      _StepKind.hardestChallenge,
      _StepKind.support,
      _StepKind.age,
      _StepKind.units,
      _StepKind.height,
      _StepKind.weight,
      _StepKind.targetWeight,
      if (_data.goal != 'maintain') _StepKind.weightLossSpeed,
      // Social-proof copy is "people lose weight faster with support" —
      // gate it on the lose goal so it doesn't show up for muscle-gain
      // or maintain users where the message wouldn't fit.
      if (_data.goal == 'lose') _StepKind.socialProof,
      _StepKind.activity,
      _StepKind.loading,
      _StepKind.result,
      _StepKind.trialReminder,
      _StepKind.ratePrompt,
    ];
  }

  _StepKind get _currentKind {
    final kinds = _kinds;
    final i = _currentPage.clamp(0, kinds.length - 1);
    return kinds[i];
  }

  int get _totalSteps => _kinds.length;
  bool get _isOnLoading => _currentKind == _StepKind.loading;
  bool get _isOnResult => _currentKind == _StepKind.result;
  bool get _isOnRatePrompt => _currentKind == _StepKind.ratePrompt;
  bool get _isOnTrialReminder => _currentKind == _StepKind.trialReminder;

  String _stepName(_StepKind kind) {
    switch (kind) {
      case _StepKind.welcome:
        return 'welcome';
      case _StepKind.confident:
        return 'confident';
      case _StepKind.goal:
        return 'goal';
      case _StepKind.obstacles:
        return 'obstacles';
      case _StepKind.gender:
        return 'gender';
      case _StepKind.calorieHistory:
        return 'calorie_history';
      case _StepKind.keepResult:
        return 'keep_result';
      case _StepKind.improveGoals:
        return 'improve_goals';
      case _StepKind.eatingObstacle:
        return 'eating_obstacle';
      case _StepKind.hardestChallenge:
        return 'hardest_challenge';
      case _StepKind.support:
        return 'support';
      case _StepKind.age:
        return 'age';
      case _StepKind.units:
        return 'units';
      case _StepKind.height:
        return 'height';
      case _StepKind.weight:
        return 'weight';
      case _StepKind.targetWeight:
        return 'target_weight';
      case _StepKind.weightLossSpeed:
        return 'weight_loss_speed';
      case _StepKind.socialProof:
        return 'social_proof';
      case _StepKind.activity:
        return 'activity';
      case _StepKind.loading:
        return 'loading';
      case _StepKind.result:
        return 'result';
      case _StepKind.trialReminder:
        return 'trial_reminder';
      case _StepKind.ratePrompt:
        return 'rate_prompt';
    }
  }

  Map<String, Object> _stepParams(int page, {String? direction}) {
    final kinds = _kinds;
    final safe = page.clamp(0, kinds.length - 1);
    final params = <String, Object>{
      'step_index': page,
      'step_name': _stepName(kinds[safe]),
      'total_steps': _totalSteps,
    };
    if (direction != null) params['direction'] = direction;
    return params;
  }

  int get _timeOnStepMs =>
      DateTime.now().difference(_stepStartedAt).inMilliseconds;

  @override
  void initState() {
    super.initState();
    _onboardingStopwatch.start();
    _stepStartedAt = DateTime.now();
    _stepsSeen.add(_currentPage);

    unawaited(
      AnalyticsService.instance.logEvent(
        'onboarding_started',
        parameters: {'total_steps': _totalSteps},
      ),
    );
    unawaited(_logStepViewed(_currentPage, direction: 'initial'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mascot images are disabled — nothing to precache. The block is kept
    // for cheap re-enable: just restore _imageOrderedKinds and uncomment.
    if (_imageOrderedKinds.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cacheWidth =
        ((MediaQuery.sizeOf(context).width - 32) *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    final cacheKey = '${isDark ? 'dark' : 'light'}:$cacheWidth';
    if (_precachedStepImagesKey == cacheKey) return;
    _precachedStepImagesKey = cacheKey;

    for (final asset in _stepImageAssetsFor(isDark: isDark)) {
      unawaited(
        precacheImage(
          ResizeImage(AssetImage(asset), width: cacheWidth),
          context,
        ),
      );
    }
  }

  Future<void> _logStepViewed(int page, {required String direction}) {
    return AnalyticsService.instance.logEvent(
      'onboarding_step_viewed',
      parameters: _stepParams(page, direction: direction),
    );
  }

  Future<void> _logStepCompleted(int page) {
    return AnalyticsService.instance.logEvent(
      'onboarding_step_completed',
      parameters: {..._stepParams(page), 'time_on_step_ms': _timeOnStepMs},
    );
  }

  List<String> _stepImageAssetsFor({required bool isDark}) {
    return isDark ? _darkStepImageAssets : _lightStepImageAssets;
  }

  String? _stepImageAsset({required bool isDark}) {
    final idx = _imageOrderedKinds.indexOf(_currentKind);
    if (idx < 0) return null;
    return _stepImageAssetsFor(isDark: isDark)[idx];
  }

  bool get _canProceed {
    switch (_currentKind) {
      case _StepKind.welcome:
      case _StepKind.confident:
      case _StepKind.keepResult:
      case _StepKind.support:
      case _StepKind.socialProof:
        return true;
      case _StepKind.goal:
        return _data.goal != null;
      case _StepKind.obstacles:
        return _data.obstacles.isNotEmpty;
      case _StepKind.gender:
        return _data.gender != null;
      case _StepKind.calorieHistory:
        return _data.calorieHistory != null;
      case _StepKind.improveGoals:
        return _data.improveGoals.isNotEmpty;
      case _StepKind.eatingObstacle:
        return _data.eatingObstacle != null;
      case _StepKind.hardestChallenge:
        return _data.hardestChallenge != null;
      case _StepKind.activity:
        return _activitySelected;
      case _StepKind.loading:
      case _StepKind.ratePrompt:
      case _StepKind.trialReminder:
        return false;
      case _StepKind.age:
      case _StepKind.units:
      case _StepKind.height:
      case _StepKind.weight:
      case _StepKind.targetWeight:
      case _StepKind.weightLossSpeed:
      case _StepKind.result:
        return true;
    }
  }

  void _goToPage(int page, {required String direction}) {
    if (!mounted) return;
    setState(() {
      _isForward = page > _currentPage;
      _currentPage = page;
    });
    _stepStartedAt = DateTime.now();
    _stepsSeen.add(page);
    unawaited(_logStepViewed(page, direction: direction));
  }

  void _next() {
    if (_isFinishing) return;
    final page = _currentPage;
    final kind = _currentKind;
    final kinds = _kinds;

    unawaited(
      AnalyticsService.instance.logEvent(
        'onboarding_step_cta_clicked',
        parameters: {
          ..._stepParams(page),
          'is_final_step': _currentPage == kinds.length - 1 ? 1 : 0,
        },
      ),
    );

    if (kind == _StepKind.weight) {
      _updateTargetWeightFromGoal();
    }

    if (kind == _StepKind.obstacles) {
      unawaited(
        AnalyticsService.instance.logEvent(
          'onboarding_obstacles_selected',
          parameters: {
            'count': _data.obstacles.length,
            'selected': _data.obstacles.join(','),
          },
        ),
      );
    }

    if (kind == _StepKind.weightLossSpeed) {
      unawaited(
        AnalyticsService.instance.logEvent(
          'onboarding_weight_loss_speed_selected',
          parameters: {'kg_per_week': _data.weightLossKgPerWeek},
        ),
      );
    }

    if (kind == _StepKind.activity) {
      _calculateResults();
    }

if (_currentPage < kinds.length - 1) {
      unawaited(_logStepCompleted(page));
      _goToPage(_currentPage + 1, direction: 'forward');
    }
  }

  void _updateTargetWeightFromGoal() {
    switch (_data.goal) {
      case 'lose':
        _data.targetWeightKg = (_data.weightKg - 5).clamp(30.0, 200.0);
      case 'gain':
        _data.targetWeightKg = (_data.weightKg + 5).clamp(30.0, 200.0);
      case 'maintain':
        _data.targetWeightKg = _data.weightKg;
      default:
        _data.targetWeightKg = _data.weightKg;
    }
  }

  void _back() {
    if (_currentPage > 0) {
      final page = _currentPage;
      _backClicksCount++;
      unawaited(
        AnalyticsService.instance.logEvent(
          'onboarding_back_clicked',
          parameters: {
            'from_step_index': page,
            'from_step_name': _stepName(_currentKind),
            'time_on_step_ms': _timeOnStepMs,
          },
        ),
      );
      _goToPage(_currentPage - 1, direction: 'back');
    }
  }

  void _calculateResults() {
    final results = TdeeCalculator.calculate(
      gender: _data.gender!,
      age: _data.age,
      heightCm: _data.heightCm,
      weightKg: _data.weightKg,
      activityMultiplier: _data.activityMultiplier,
      goal: _data.goal!,
      weightLossKgPerWeek: _data.weightLossKgPerWeek,
    );

    _data.calorieGoal = results['calories'];
    _data.proteinGoal = results['protein'];
    _data.fatGoal = results['fat'];
    _data.carbsGoal = results['carbs'];

    _data.targetDate = TdeeCalculator.estimateTargetDate(
      currentWeight: _data.weightKg,
      targetWeight: _data.targetWeightKg,
      goal: _data.goal!,
      weightLossKgPerWeek: _data.weightLossKgPerWeek,
    );
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    try {
      await AuthService().markOnboardingCompleted();

      _onboardingCompleted = true;
      _onboardingStopwatch.stop();
      unawaited(
        AnalyticsService.instance.logEvent(
          'onboarding_completed',
          parameters: {
            'total_steps': _totalSteps,
            'steps_seen': _stepsSeen.length,
            'back_clicks_count': _backClicksCount,
            'total_duration_ms': _onboardingStopwatch.elapsedMilliseconds,
          },
        ),
      );

      if (mounted) context.go('/paywall');

      unawaited(_persistOnboardingSettings());
    } catch (e) {
      debugPrint('Onboarding _finish error: $e');
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  Future<void> _persistOnboardingSettings() async {
    try {
      final db = await AppDatabase.getInstance();

      // Build the map first so the same key/value pairs go to the local
      // DB and the cloud sync push, keeping them in lock-step. The
      // sync push is a no-op when the user is a guest; for someone
      // who's already logged in (e.g. running onboarding again to
      // recompute goals) it carries the new values to their account.
      final settings = <String, String>{
        'onboarding_completed': 'true',
        'user_goal': _data.goal!,
        'user_gender': _data.gender!,
        'user_age': '${_data.age}',
        'unit_system': _data.unitSystem,
        'user_height': '${_data.heightCm.round()}',
        'user_weight': _data.weightKg.toStringAsFixed(1),
        'user_target_weight': _data.targetWeightKg.toStringAsFixed(1),
        'user_activity_level': _data.activityMultiplier.toString(),
        'calorie_goal': '${_data.calorieGoal!.round()}',
        'protein_goal': '${_data.proteinGoal!.round()}',
        'fat_goal': '${_data.fatGoal!.round()}',
        'carbs_goal': '${_data.carbsGoal!.round()}',
        'user_obstacles': _data.obstacles.join(','),
        'user_weight_loss_speed': _data.weightLossKgPerWeek.toStringAsFixed(1),
        if (_data.psychotype != null) 'user_psychotype': _data.psychotype!,
        if (_data.calorieHistory != null)
          'user_calorie_history': _data.calorieHistory!,
        'user_improve_goals': _data.improveGoals.join(','),
        if (_data.eatingObstacle != null)
          'user_eating_obstacle': _data.eatingObstacle!,
        if (_data.hardestChallenge != null)
          'user_hardest_challenge': _data.hardestChallenge!,
      };
      for (final entry in settings.entries) {
        await db.setSetting(entry.key, entry.value);
      }
      unawaited(LoginSyncService().pushSettings(settings));
    } catch (e) {
      debugPrint('Onboarding settings persist error: $e');
    }
  }

  void _onLoadingFinished() {
    unawaited(_logStepCompleted(_currentPage));
    final kinds = _kinds;
    final resultIdx = kinds.indexOf(_StepKind.result);
    if (resultIdx >= 0) {
      _goToPage(resultIdx, direction: 'forward');
    }
  }

  @override
  void dispose() {
    if (!_onboardingCompleted) {
      unawaited(
        AnalyticsService.instance.logEvent(
          'onboarding_exited',
          parameters: {
            ..._stepParams(_currentPage),
            'steps_seen': _stepsSeen.length,
            'back_clicks_count': _backClicksCount,
            'total_duration_ms': _onboardingStopwatch.elapsedMilliseconds,
          },
        ),
      );
    }
    super.dispose();
  }

  Widget _buildCurrentStep() {
    final kind = _currentKind;
    final key = ValueKey('${_stepName(kind)}_$_currentPage');
    switch (kind) {
      case _StepKind.welcome:
        return WelcomeStep(key: key);
      case _StepKind.confident:
        return ConfidentStep(key: key);
      case _StepKind.goal:
        return GoalStep(
          key: key,
          selected: _data.goal,
          onChanged: (v) => setState(() {
            _data.goal = v;
            // Reset the speed slider to the goal-appropriate default so
            // the thumb starts at the visual centre of the new scale.
            _data.weightLossKgPerWeek = v == 'gain' ? 0.3 : 0.5;
            // Re-sync target weight with the new goal so the speed
            // step always has a non-zero `diff` and the projected date
            // changes with the slider. Without this, switching from
            // 'maintain' (which sets target == current) to 'lose'
            // would leave target stuck at current → date never moves.
            _updateTargetWeightFromGoal();
          }),
        );
      case _StepKind.obstacles:
        return ObstaclesStep(
          key: key,
          selected: _data.obstacles,
          onChanged: (v) => setState(() => _data.obstacles = v),
        );
      case _StepKind.gender:
        return GenderStep(
          key: key,
          selected: _data.gender,
          onChanged: (v) => setState(() => _data.gender = v),
        );
      case _StepKind.calorieHistory:
        return CalorieHistoryStep(
          key: key,
          selected: _data.calorieHistory,
          gender: _data.gender,
          onChanged: (v) => setState(() => _data.calorieHistory = v),
        );
      case _StepKind.keepResult:
        return KeepResultStep(key: key);
      case _StepKind.improveGoals:
        return ImproveGoalsStep(
          key: key,
          selected: _data.improveGoals,
          onChanged: (v) => setState(() => _data.improveGoals = v),
        );
      case _StepKind.eatingObstacle:
        return EatingObstacleStep(
          key: key,
          selected: _data.eatingObstacle,
          onChanged: (v) => setState(() => _data.eatingObstacle = v),
        );
      case _StepKind.hardestChallenge:
        return HardestChallengeStep(
          key: key,
          selected: _data.hardestChallenge,
          onChanged: (v) => setState(() => _data.hardestChallenge = v),
        );
      case _StepKind.support:
        return SupportStep(key: key, gender: _data.gender);
      case _StepKind.age:
        return AgeStep(
          key: key,
          age: _data.age,
          onChanged: (v) => setState(() => _data.age = v),
        );
      case _StepKind.units:
        return UnitsStep(
          key: key,
          selected: _data.unitSystem,
          onChanged: (v) => setState(() => _data.unitSystem = v),
        );
      case _StepKind.height:
        return HeightStep(
          key: key,
          heightCm: _data.heightCm,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.heightCm = v),
        );
      case _StepKind.weight:
        return WeightStep(
          key: key,
          weightKg: _data.weightKg,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.weightKg = v),
        );
      case _StepKind.targetWeight:
        return TargetWeightStep(
          key: key,
          targetWeight: _data.targetWeightKg,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.targetWeightKg = v),
        );
      case _StepKind.weightLossSpeed:
        return WeightLossSpeedStep(
          key: key,
          goal: _data.goal ?? 'lose',
          currentWeightKg: _data.weightKg,
          targetWeightKg: _data.targetWeightKg,
          kgPerWeek: _data.weightLossKgPerWeek,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.weightLossKgPerWeek = v),
        );
      case _StepKind.socialProof:
        return SocialProofStep(key: key);
      case _StepKind.activity:
        return ActivityStep(
          key: key,
          selected: _activitySelected ? _data.activityMultiplier : null,
          onChanged: (v) {
            setState(() {
              _data.activityMultiplier = v;
              _activitySelected = true;
            });
          },
        );
      case _StepKind.loading:
        return LoadingStep(key: key, onFinished: _onLoadingFinished);
      case _StepKind.result:
        return ResultStep(key: key, data: _data);
      case _StepKind.trialReminder:
        return TrialReminderStep(key: key, onNext: _next);
      case _StepKind.ratePrompt:
        return RatePromptStep(
          key: key,
          onCompleted: _onRatePromptCompleted,
        );
    }
  }

  void _onRatePromptCompleted(int? rating, bool submittedReview) {
    unawaited(
      AnalyticsService.instance.logEvent(
        'onboarding_rate_prompted',
        parameters: {
          'rating': ?rating,
          'submitted_review': submittedReview ? 1 : 0,
        },
      ),
    );
    unawaited(_logStepCompleted(_currentPage));
    _finish();
  }

  Widget _buildProgressHeader(
    BuildContext context,
    bool isDark,
    bool isLoading,
  ) {
    final cs = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final isFirstStep = _currentPage == 0;
    final canGoBack = !isFirstStep && !isLoading && !_isOnRatePrompt;
    final total = _totalSteps;
    final progressStep = (_currentPage + 1).clamp(1, total);
    final progressValue = progressStep / total;
    final headerBg = isDark ? AppColors.darkOnBack : AppColors.lightOnBack;
    final controlBg = isDark ? AppColors.darkOnBack : AppColors.lightOnBack;
    final borderColor = isDark ? AppColors.lineDT50 : AppColors.lineLight100;
    final trackColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    return SizedBox(
      height: topInset + 64,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: headerBg,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          // Soft drop shadow lifts the header off the scaffold — both
          // surfaces are near-white, so without it the header bleeds
          // into the content area and the back button becomes invisible.
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: _RoundedBottomBorderPainter(
            color: borderColor,
            radius: 24,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 16),
            child: Row(
              children: [
                if (isFirstStep)
                  const SizedBox(width: 48, height: 36)
                else
                  Opacity(
                    opacity: canGoBack ? 1 : 0.2,
                    child: IgnorePointer(
                      ignoring: !canGoBack,
                      child: Container(
                        width: 48,
                        height: 36,
                        decoration: BoxDecoration(
                          color: controlBg,
                          borderRadius: BorderRadius.circular(122),
                          border: Border.all(color: borderColor),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: _back,
                          icon: Icon(
                            Icons.arrow_back,
                            color: cs.onSurface,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 17),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: SizedBox(
                        height: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: trackColor),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: progressValue),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            builder: (context, value, _) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: value,
                                  heightFactor: 1,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF317BFE),
                                          Color(0xFF31AFFE),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Phantom spacer mirroring the back-button + gap on the left,
                // so the progress bar reads as horizontally centred even
                // though there's no control on the right.
                const SizedBox(width: 17),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = _isOnLoading;
    final isResult = _isOnResult;
    final headerBg = isDark ? AppColors.darkOnBack : AppColors.lightOnBack;
    final stepImageAsset = _stepImageAsset(isDark: isDark);
    final stepImageCacheWidth = stepImageAsset == null
        ? null
        : ((MediaQuery.sizeOf(context).width - 32) *
                  MediaQuery.devicePixelRatioOf(context))
              .round();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showCta = !isLoading && !_isOnRatePrompt && !_isOnTrialReminder;

    return DefaultTextStyle.merge(
      // Onboarding text uses tight tracking — Inter/Cyrillic at title sizes
      // looks loose with the Material 3 default bodyMedium letterSpacing
      // of 0.25 cascading down to Text widgets that don't override it.
      style: const TextStyle(letterSpacing: 0),
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0 && !isLoading && !_isOnRatePrompt) {
          _back();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBack3 : AppColors.lightBack3,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: headerBg,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: Column(
            children: [
              _buildProgressHeader(context, isDark, isLoading),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final hasStepImage = stepImageAsset != null;
                    final stepImageWidth =
                        constraints.maxWidth - _stepImageHorizontalPadding * 2;
                    final stepImageHeight = hasStepImage
                        ? (stepImageWidth / _stepImageAspectRatio).clamp(
                            0.0,
                            constraints.maxHeight * 0.28,
                          )
                        : 0.0;
                    final stepImageBottom = isLoading
                        ? 0.0
                        : bottomInset + _stepImageBottomOffset;
                    final contentBottomPadding = isLoading || !showCta
                        ? 0.0
                        : hasStepImage
                            ? stepImageBottom +
                                  stepImageHeight +
                                  _stepImageContentGap
                            // No step image (e.g. result step): reserve space
                            // for the floating CTA button so scrollable content
                            // doesn't get hidden behind it at the bottom.
                            : bottomInset +
                                  _ctaButtonBottomMargin +
                                  _ctaButtonHeight +
                                  _stepImageContentGap;

                    return Stack(
                      children: [
                        if (stepImageAsset != null)
                          Positioned(
                            left: _stepImageHorizontalPadding,
                            right: _stepImageHorizontalPadding,
                            bottom: stepImageBottom,
                            child: IgnorePointer(
                              child: SizedBox(
                                height: stepImageHeight,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  reverseDuration: const Duration(
                                    milliseconds: 220,
                                  ),
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            for (final child
                                                in previousChildren)
                                              child,
                                            ?currentChild,
                                          ],
                                        );
                                      },
                                  transitionBuilder: (child, animation) {
                                    final isIncoming =
                                        child.key == ValueKey(stepImageAsset);
                                    final opacity = CurvedAnimation(
                                      parent: animation,
                                      curve: isIncoming
                                          ? const Interval(
                                              0.45,
                                              1,
                                              curve: Curves.easeOutCubic,
                                            )
                                          : const Interval(
                                              0.55,
                                              1,
                                              curve: Curves.easeInCubic,
                                            ),
                                    );

                                    final offset =
                                        Tween<Offset>(
                                          begin: const Offset(0, 0.12),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: isIncoming
                                                ? Curves.easeOutCubic
                                                : Curves.easeInCubic,
                                          ),
                                        );

                                    return FadeTransition(
                                      opacity: opacity,
                                      child: SlideTransition(
                                        position: offset,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    stepImageAsset,
                                    key: ValueKey(stepImageAsset),
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    cacheWidth: stepImageCacheWidth,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: SafeArea(
                            top: false,
                            // Apply bottom safe-area when there's no
                            // floating CTA — otherwise step content
                            // could slip under the home indicator.
                            bottom: isLoading || !showCta,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: contentBottomPadding,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                reverseDuration: const Duration(
                                  milliseconds: 250,
                                ),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        children: [
                                          for (final child in previousChildren)
                                            Positioned.fill(child: child),
                                          if (currentChild != null)
                                            Positioned.fill(
                                              child: currentChild,
                                            ),
                                        ],
                                      );
                                    },
                                transitionBuilder: (child, animation) {
                                  final isIncoming =
                                      child.key ==
                                      ValueKey(
                                        '${_stepName(_currentKind)}_$_currentPage',
                                      );
                                  final slideBegin = _isForward
                                      ? (isIncoming ? 0.25 : -0.15)
                                      : (isIncoming ? -0.25 : 0.15);
                                  final slide = Tween<Offset>(
                                    begin: Offset(slideBegin, 0),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  final fade = isIncoming
                                      ? Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: const Interval(
                                              0.0,
                                              0.6,
                                              curve: Curves.easeOut,
                                            ),
                                          ),
                                        )
                                      : animation;
                                  return SlideTransition(
                                    position: slide,
                                    child: FadeTransition(
                                      opacity: fade,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildCurrentStep(),
                              ),
                            ),
                          ),
                        ),
                        if (showCta)
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: bottomInset + _ctaButtonBottomMargin,
                            child: SizedBox(
                              width: double.infinity,
                              height: _ctaButtonHeight,
                              child: ElevatedButton(
                                onPressed: _isFinishing
                                    ? () {}
                                    : (_canProceed ? _next : null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canProceed || _isFinishing
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.darkDisabledBg
                                            : AppColors.lightDisabledBg),
                                  foregroundColor: _canProceed || _isFinishing
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkDisabledContent
                                            : AppColors.lightDisabledContent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isFinishing
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _currentKind == _StepKind.welcome
                                            ? context.l10n.onbWelcomeCta
                                            : isResult
                                                ? context.l10n.resultOpenPlan
                                                : context.l10n.onboardingNext,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _RoundedBottomBorderPainter extends CustomPainter {
  const _RoundedBottomBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final halfStroke = paint.strokeWidth / 2;
    final bottom = size.height - halfStroke;
    final left = halfStroke;
    final right = size.width - halfStroke;
    final r = radius.clamp(0, size.width / 2);

    final path = Path()
      ..moveTo(left, bottom - r)
      ..quadraticBezierTo(left, bottom, left + r, bottom)
      ..lineTo(right - r, bottom)
      ..quadraticBezierTo(right, bottom, right, bottom - r);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundedBottomBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
