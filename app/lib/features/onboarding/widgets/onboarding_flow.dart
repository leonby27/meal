import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/core/database/app_database.dart';
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
  static const _totalSteps = 10;

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

  void _goToPage(int page) {
    if (!mounted) return;
    setState(() {
      _isForward = page > _currentPage;
      _currentPage = page;
    });
  }

  void _next() {
    if (_isFinishing) return;

    if (_currentPage == 5) {
      _updateTargetWeightFromGoal();
    }

    if (_currentPage == 7) {
      _calculateResults();
    }

    if (_currentPage == 9) {
      _finish();
      return;
    }

    if (_currentPage < _totalSteps - 1) {
      _goToPage(_currentPage + 1);
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
      _goToPage(_currentPage - 1);
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
    _goToPage(9);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = _currentPage == 8;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0 && !isLoading) _back();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBack2 : AppColors.lightBack2,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_currentPage > 0 && !isLoading) ...[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: _back,
                            icon: Icon(Icons.arrow_back, color: cs.onSurface),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: (_currentPage + 1) / _totalSteps,
                              end: (_currentPage + 1) / _totalSteps,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 20,
                                  backgroundColor: cs.outline.withAlpha(60),
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.primary,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  reverseDuration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      children: [
                        for (final child in previousChildren)
                          Positioned.fill(child: child),
                        if (currentChild != null)
                          Positioned.fill(child: currentChild),
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final isIncoming = child.key == ValueKey(_currentPage);
                    final slideBegin = _isForward
                        ? (isIncoming ? 0.25 : -0.15)
                        : (isIncoming ? -0.25 : 0.15);
                    final slide = Tween<Offset>(
                      begin: Offset(slideBegin, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    final fade = isIncoming
                        ? Tween<double>(begin: 0.0, end: 1.0).animate(
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
                      child: FadeTransition(opacity: fade, child: child),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ),
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
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
                              _currentPage == 9
                                  ? context.l10n.onboardingStart
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
          ),
        ),
      ),
    );
  }
}
