import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/features/onboarding/models/onboarding_data.dart';
import 'package:meal_tracker/features/onboarding/services/tdee_calculator.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/goal_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/gender_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/age_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/units_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/height_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/weight_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/target_weight_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/activity_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/loading_step.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/result_step.dart';
// Social-proof steps are temporarily disabled — files kept on disk for
// when we return to polish them.
// import 'package:meal_tracker/features/onboarding/widgets/steps/social_proof_scale_step.dart';
// import 'package:meal_tracker/features/onboarding/widgets/steps/social_proof_accuracy_step.dart';
// import 'package:meal_tracker/features/onboarding/widgets/steps/social_proof_science_step.dart';

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
  static const _totalSteps = 10;
  static const _progressSteps = 8;
  static const _resultPage = 9;
  static const _finalPage = 9;
  static const _stepImageAspectRatio = 1024 / 632;
  static const _stepImageHorizontalPadding = 16.0;
  static const _stepImageBottomOffset = 84.0;
  static const _stepImageContentGap = 12.0;
  static const _stepNames = [
    'goal',
    'gender',
    'age',
    'units',
    'height',
    'weight',
    'target_weight',
    'activity',
    'loading',
    'result',
  ];
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

  String _stepName(int page) {
    if (page < 0 || page >= _stepNames.length) return 'unknown';
    return _stepNames[page];
  }

  Map<String, Object> _stepParams(int page, {String? direction}) {
    final params = <String, Object>{
      'step_index': page,
      'step_name': _stepName(page),
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
    if (_currentPage < 0 || _currentPage >= _progressSteps) return null;
    return _stepImageAssetsFor(isDark: isDark)[_currentPage];
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _data.goal != null;
      case 1:
        return _data.gender != null;
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
        return true;
      case 7:
        return _activitySelected;
      case 8:
        return false;
      case 9:
        return true;
      default:
        return false;
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

    unawaited(
      AnalyticsService.instance.logEvent(
        'onboarding_step_cta_clicked',
        parameters: {
          ..._stepParams(page),
          'is_final_step': page == _finalPage ? 1 : 0,
        },
      ),
    );

    if (_currentPage == 5) {
      _updateTargetWeightFromGoal();
    }

    if (_currentPage == 7) {
      _calculateResults();
    }

    if (_currentPage == _finalPage) {
      unawaited(_logStepCompleted(page));
      _finish();
      return;
    }

    if (_currentPage < _totalSteps - 1) {
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
            'from_step_name': _stepName(page),
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
    );

    _data.calorieGoal = results['calories'];
    _data.proteinGoal = results['protein'];
    _data.fatGoal = results['fat'];
    _data.carbsGoal = results['carbs'];

    _data.targetDate = TdeeCalculator.estimateTargetDate(
      currentWeight: _data.weightKg,
      targetWeight: _data.targetWeightKg,
      goal: _data.goal!,
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

      await db.setSetting('onboarding_completed', 'true');
      await db.setSetting('user_goal', _data.goal!);
      await db.setSetting('user_gender', _data.gender!);
      await db.setSetting('user_age', '${_data.age}');
      await db.setSetting('unit_system', _data.unitSystem);
      await db.setSetting('user_height', '${_data.heightCm.round()}');
      await db.setSetting('user_weight', _data.weightKg.toStringAsFixed(1));
      await db.setSetting(
        'user_target_weight',
        _data.targetWeightKg.toStringAsFixed(1),
      );
      await db.setSetting(
        'user_activity_level',
        _data.activityMultiplier.toString(),
      );
      await db.setSetting('calorie_goal', '${_data.calorieGoal!.round()}');
      await db.setSetting('protein_goal', '${_data.proteinGoal!.round()}');
      await db.setSetting('fat_goal', '${_data.fatGoal!.round()}');
      await db.setSetting('carbs_goal', '${_data.carbsGoal!.round()}');
    } catch (e) {
      debugPrint('Onboarding settings persist error: $e');
    }
  }

  void _onLoadingFinished() {
    unawaited(_logStepCompleted(_currentPage));
    _goToPage(_resultPage, direction: 'forward');
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
    switch (_currentPage) {
      case 0:
        return GoalStep(
          key: const ValueKey(0),
          selected: _data.goal,
          onChanged: (v) => setState(() => _data.goal = v),
        );
      case 1:
        return GenderStep(
          key: const ValueKey(1),
          selected: _data.gender,
          onChanged: (v) => setState(() => _data.gender = v),
        );
      case 2:
        return AgeStep(
          key: const ValueKey(2),
          age: _data.age,
          onChanged: (v) => setState(() => _data.age = v),
        );
      case 3:
        return UnitsStep(
          key: const ValueKey(3),
          selected: _data.unitSystem,
          onChanged: (v) => setState(() => _data.unitSystem = v),
        );
      case 4:
        return HeightStep(
          key: const ValueKey(4),
          heightCm: _data.heightCm,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.heightCm = v),
        );
      case 5:
        return WeightStep(
          key: const ValueKey(5),
          weightKg: _data.weightKg,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.weightKg = v),
        );
      case 6:
        return TargetWeightStep(
          key: const ValueKey(6),
          targetWeight: _data.targetWeightKg,
          goal: _data.goal,
          isImperial: _data.isImperial,
          onChanged: (v) => setState(() => _data.targetWeightKg = v),
        );
      case 7:
        return ActivityStep(
          key: const ValueKey(7),
          selected: _activitySelected ? _data.activityMultiplier : null,
          onChanged: (v) {
            setState(() {
              _data.activityMultiplier = v;
              _activitySelected = true;
            });
          },
        );
      case 8:
        return LoadingStep(
          key: const ValueKey(8),
          onFinished: _onLoadingFinished,
        );
      case 9:
        return ResultStep(key: const ValueKey(9), data: _data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressHeader(
    BuildContext context,
    bool isDark,
    bool isLoading,
  ) {
    final cs = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final canGoBack = _currentPage > 0 && !isLoading;
    final progressStep = (_currentPage + 1).clamp(1, _progressSteps);
    final progressValue = progressStep / _progressSteps;
    final headerBg = isDark
        ? AppColors.darkOnBackAlpha30
        : AppColors.lightOnBackAlpha30;
    final controlBg = isDark ? AppColors.darkOnBack : AppColors.lightOnBack;
    final counterBg = isDark ? AppColors.darkOnBack : AppColors.lightOnBack;
    final borderColor = isDark ? AppColors.lineDT50 : AppColors.lineLight100;
    final trackColor = isDark ? AppColors.lineDT300 : AppColors.lineLight300;

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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth = constraints.maxWidth < 230
                          ? constraints.maxWidth
                          : 230.0;

                      return Align(
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: SizedBox(
                            width: trackWidth,
                            height: 20,
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
                      );
                    },
                  ),
                ),
                const SizedBox(width: 17),
                Container(
                  width: 48,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: counterBg,
                    borderRadius: BorderRadius.circular(122),
                  ),
                  child: Text(
                    '$progressStep/$_progressSteps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 22 / 16,
                    ),
                  ),
                ),
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
    final isLoading = _currentPage == 8;
    final headerBg = isDark
        ? AppColors.darkOnBackAlpha30
        : AppColors.lightOnBackAlpha30;
    final stepImageAsset = _stepImageAsset(isDark: isDark);
    final stepImageCacheWidth = stepImageAsset == null
        ? null
        : ((MediaQuery.sizeOf(context).width - 32) *
                  MediaQuery.devicePixelRatioOf(context))
              .round();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0 && !isLoading) _back();
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
                    final contentBottomPadding = hasStepImage
                        ? stepImageBottom +
                              stepImageHeight +
                              _stepImageContentGap
                        : 0.0;

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
                            bottom: isLoading,
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
                                      child.key == ValueKey(_currentPage);
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
                        if (!isLoading)
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: bottomInset + 16,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: AppTheme.cardEdgeBorder(isDark: isDark),
                                boxShadow: AppTheme.cardEdgeShadows(
                                  isDark: isDark,
                                ),
                              ),
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
                                        _currentPage == _finalPage
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
