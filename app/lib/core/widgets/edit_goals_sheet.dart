import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/login_sync_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/services/tdee_calculator.dart';

/// Bottom sheet that edits the daily KBJU goals in two modes:
///
/// • **Plan** (default) — user edits the underlying onboarding params
///   (gender, age, height, weight, target weight, activity, goal type)
///   and sees the calorie/macro targets recomputed live by
///   `TdeeCalculator`.
/// • **Custom** — user types KBJU directly with bidirectional cal ↔
///   macro sync via the same 30/25/45 split / Atwater conversion.
///
/// The chosen mode is persisted in `goals_mode` so the sheet reopens
/// where the user left it. Saves persist KBJU + (in plan mode) plan
/// params, and pop with `true`.
class EditGoalsSheet extends StatefulWidget {
  const EditGoalsSheet({
    super.key,
    required this.initialCalories,
    required this.initialProtein,
    required this.initialFat,
    required this.initialCarbs,
  });

  final double initialCalories;
  final double initialProtein;
  final double initialFat;
  final double initialCarbs;

  @override
  State<EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<EditGoalsSheet> {
  // KBJU controllers — driven either by plan recompute or by user.
  late final TextEditingController _calCtl;
  late final TextEditingController _protCtl;
  late final TextEditingController _fatCtl;
  late final TextEditingController _carbsCtl;

  // Plan-mode params, async-loaded from settings.
  String _goal = 'lose';
  String _gender = 'female';
  double _activity = 1.375;
  double _weightLossKgPerWeek = 0.5;
  late final TextEditingController _ageCtl;
  late final TextEditingController _heightCtl;
  late final TextEditingController _weightCtl;
  late final TextEditingController _targetWeightCtl;

  String _mode = 'plan'; // 'plan' | 'custom'
  bool _loaded = false;
  bool _saving = false;
  // Re-entry guard for cal ↔ P/F/C sync (custom mode) and plan
  // recompute writing into KBJU controllers.
  bool _syncing = false;

  // Atwater + onboarding shares — kept in sync with TdeeCalculator.
  static const _proteinShare = 0.30;
  static const _fatShare = 0.25;
  static const _carbsShare = 0.45;

  @override
  void initState() {
    super.initState();
    _calCtl = TextEditingController(
      text: widget.initialCalories.toInt().toString(),
    );
    _protCtl = TextEditingController(
      text: widget.initialProtein.toInt().toString(),
    );
    _fatCtl = TextEditingController(
      text: widget.initialFat.toInt().toString(),
    );
    _carbsCtl = TextEditingController(
      text: widget.initialCarbs.toInt().toString(),
    );
    _ageCtl = TextEditingController();
    _heightCtl = TextEditingController();
    _weightCtl = TextEditingController();
    _targetWeightCtl = TextEditingController();
    _loadParams();
  }

  Future<void> _loadParams() async {
    final db = await AppDatabase.getInstance();
    final mode = await db.getSetting('goals_mode') ?? 'plan';
    final goal = await db.getSetting('user_goal') ?? 'lose';
    final gender = await db.getSetting('user_gender') ?? 'female';
    final age = await db.getSetting('user_age') ?? '26';
    final height = await db.getSetting('user_height') ?? '170';
    final weight = await db.getSetting('user_weight') ?? '70';
    final targetWeight = await db.getSetting('user_target_weight') ?? '65';
    final activity = double.tryParse(
          await db.getSetting('user_activity_level') ?? '',
        ) ??
        1.375;
    final weightLossSpeed = double.tryParse(
          await db.getSetting('user_weight_loss_speed') ?? '',
        ) ??
        0.5;

    if (!mounted) return;
    setState(() {
      _mode = mode;
      _goal = goal;
      _gender = gender;
      _activity = activity;
      _weightLossKgPerWeek = weightLossSpeed;
      _ageCtl.text = age;
      _heightCtl.text = _formatNumeric(height);
      _weightCtl.text = _formatNumeric(weight);
      _targetWeightCtl.text = _formatNumeric(targetWeight);
      _loaded = true;
    });

    // Plan-param fields drive the KBJU recompute when in plan mode.
    _ageCtl.addListener(_onPlanParamChanged);
    _heightCtl.addListener(_onPlanParamChanged);
    _weightCtl.addListener(_onPlanParamChanged);
    _targetWeightCtl.addListener(_onPlanParamChanged);

    if (_mode == 'custom') {
      _enableKbjuListeners();
    }
  }

  String _formatNumeric(String raw) {
    final d = double.tryParse(raw);
    if (d == null) return raw;
    return d == d.roundToDouble() ? d.toInt().toString() : raw;
  }

  void _enableKbjuListeners() {
    _calCtl.addListener(_onCaloriesChanged);
    _protCtl.addListener(_onMacrosChanged);
    _fatCtl.addListener(_onMacrosChanged);
    _carbsCtl.addListener(_onMacrosChanged);
  }

  void _disableKbjuListeners() {
    _calCtl.removeListener(_onCaloriesChanged);
    _protCtl.removeListener(_onMacrosChanged);
    _fatCtl.removeListener(_onMacrosChanged);
    _carbsCtl.removeListener(_onMacrosChanged);
  }

  @override
  void dispose() {
    _disableKbjuListeners();
    _ageCtl.removeListener(_onPlanParamChanged);
    _heightCtl.removeListener(_onPlanParamChanged);
    _weightCtl.removeListener(_onPlanParamChanged);
    _targetWeightCtl.removeListener(_onPlanParamChanged);
    _calCtl.dispose();
    _protCtl.dispose();
    _fatCtl.dispose();
    _carbsCtl.dispose();
    _ageCtl.dispose();
    _heightCtl.dispose();
    _weightCtl.dispose();
    _targetWeightCtl.dispose();
    super.dispose();
  }

  void _setSilently(TextEditingController ctl, String value) {
    if (ctl.text == value) return;
    ctl.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  // ── Plan-mode recompute ─────────────────────────────────────────
  void _onPlanParamChanged() {
    if (_mode != 'plan') return;
    _recomputeFromPlan();
  }

  void _recomputeFromPlan() {
    final age = int.tryParse(_ageCtl.text) ?? 0;
    final height = double.tryParse(_heightCtl.text) ?? 0;
    final weight = double.tryParse(_weightCtl.text) ?? 0;
    if (age <= 0 || height <= 0 || weight <= 0) return;

    final result = TdeeCalculator.calculate(
      gender: _gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      activityMultiplier: _activity,
      goal: _goal,
      weightLossKgPerWeek: _weightLossKgPerWeek,
    );

    _syncing = true;
    _setSilently(_calCtl, (result['calories'] ?? 0).toInt().toString());
    _setSilently(_protCtl, (result['protein'] ?? 0).toInt().toString());
    _setSilently(_fatCtl, (result['fat'] ?? 0).toInt().toString());
    _setSilently(_carbsCtl, (result['carbs'] ?? 0).toInt().toString());
    _syncing = false;
  }

  // ── Custom-mode bidirectional sync ──────────────────────────────
  void _onCaloriesChanged() {
    if (_syncing) return;
    if (_calCtl.text.isEmpty) return;
    final cal = double.tryParse(_calCtl.text);
    if (cal == null || cal < 0) return;
    _syncing = true;
    _setSilently(_protCtl, (cal * _proteinShare / 4).round().toString());
    _setSilently(_fatCtl, (cal * _fatShare / 9).round().toString());
    _setSilently(_carbsCtl, (cal * _carbsShare / 4).round().toString());
    _syncing = false;
  }

  void _onMacrosChanged() {
    if (_syncing) return;
    if (_protCtl.text.isEmpty &&
        _fatCtl.text.isEmpty &&
        _carbsCtl.text.isEmpty) {
      return;
    }
    final p = double.tryParse(_protCtl.text) ?? 0;
    final f = double.tryParse(_fatCtl.text) ?? 0;
    final c = double.tryParse(_carbsCtl.text) ?? 0;
    final cal = (p * 4 + f * 9 + c * 4).round();
    _syncing = true;
    _setSilently(_calCtl, cal.toString());
    _syncing = false;
  }

  // ── Mode switch ─────────────────────────────────────────────────
  void _switchToCustom() {
    setState(() => _mode = 'custom');
    _enableKbjuListeners();
  }

  void _switchToPlan() {
    _disableKbjuListeners();
    setState(() => _mode = 'plan');
    _recomputeFromPlan();
  }

  // ── Save ────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = await AppDatabase.getInstance();
    final settings = <String, String>{
      'goals_mode': _mode,
      'calorie_goal': _calCtl.text,
      'protein_goal': _protCtl.text,
      'fat_goal': _fatCtl.text,
      'carbs_goal': _carbsCtl.text,
    };
    if (_mode == 'plan') {
      settings.addAll({
        'user_goal': _goal,
        'user_gender': _gender,
        'user_age': _ageCtl.text,
        'user_height': _heightCtl.text,
        'user_weight': _weightCtl.text,
        'user_target_weight': _targetWeightCtl.text,
        'user_activity_level': _activity.toString(),
        'user_weight_loss_speed': _weightLossKgPerWeek.toStringAsFixed(1),
      });
    }
    for (final entry in settings.entries) {
      await db.setSetting(entry.key, entry.value);
    }
    unawaited(LoginSyncService().pushSettings(settings));
    if (mounted) Navigator.pop(context, true);
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final sheetBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final closeBtnBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        l10n.myGoals,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 24 / 18,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: closeBtnBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_loaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _mode == 'plan'
                        ? _buildPlanBody(isDark, cs, l10n)
                        : _buildCustomBody(isDark, cs, l10n),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (!_loaded || _saving) ? null : _save,
                    child: Text(
                      l10n.save,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  // ── Plan-mode body ──────────────────────────────────────────────
  Widget _buildPlanBody(bool isDark, ColorScheme cs, dynamic l10n) {
    final blockBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final secondary = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final goalOptions = <_DropdownOption<String>>[
      _DropdownOption(value: 'lose', label: l10n.goalLoseWeight),
      _DropdownOption(value: 'maintain', label: l10n.goalMaintainWeight),
      _DropdownOption(value: 'gain', label: l10n.goalGainWeight),
    ];
    final genderOptions = <_DropdownOption<String>>[
      _DropdownOption(value: 'male', label: l10n.genderMale),
      _DropdownOption(value: 'female', label: l10n.genderFemale),
    ];
    final activityOptions = <_DropdownOption<double>>[
      _DropdownOption(value: 1.2, label: l10n.activitySedentary),
      _DropdownOption(value: 1.375, label: l10n.activityLight),
      _DropdownOption(value: 1.55, label: l10n.activityModerate),
      _DropdownOption(value: 1.725, label: l10n.activityHigh),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: blockBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Column(
              children: [
                _PlanDropdownRow<String>(
                  label: l10n.goalsParamGoal,
                  value: _goal,
                  options: goalOptions,
                  isDark: isDark,
                  primary: cs.onSurface,
                  onChanged: (v) {
                    setState(() => _goal = v);
                    _recomputeFromPlan();
                  },
                ),
                _PlanRowDivider(isDark: isDark),
                _PlanDropdownRow<String>(
                  label: l10n.goalsParamGender,
                  value: _gender,
                  options: genderOptions,
                  isDark: isDark,
                  primary: cs.onSurface,
                  onChanged: (v) {
                    setState(() => _gender = v);
                    _recomputeFromPlan();
                  },
                ),
                _PlanRowDivider(isDark: isDark),
                _PlanInputRow(
                  label: l10n.goalsParamAge,
                  controller: _ageCtl,
                  suffix: '',
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                _PlanRowDivider(isDark: isDark),
                _PlanInputRow(
                  label: l10n.goalsParamHeight,
                  controller: _heightCtl,
                  suffix: 'cm',
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                _PlanRowDivider(isDark: isDark),
                _PlanInputRow(
                  label: l10n.goalsParamWeight,
                  controller: _weightCtl,
                  suffix: 'kg',
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                _PlanRowDivider(isDark: isDark),
                _PlanInputRow(
                  label: l10n.goalsParamTargetWeight,
                  controller: _targetWeightCtl,
                  suffix: 'kg',
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                _PlanRowDivider(isDark: isDark),
                _PlanDropdownRow<double>(
                  label: l10n.goalsParamActivity,
                  value: _activity,
                  options: activityOptions,
                  isDark: isDark,
                  primary: cs.onSurface,
                  onChanged: (v) {
                    setState(() => _activity = v);
                    _recomputeFromPlan();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.goalsPlanNote,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            color: secondary,
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: blockBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _GoalSummaryCell(
                    iconAsset: 'assets/icons/cal.svg',
                    value: _calCtl.text,
                    unit: 'kcal',
                    primary: cs.onSurface,
                    secondary: secondary,
                  ),
                ),
                Expanded(
                  child: _GoalSummaryCell(
                    iconAsset: 'assets/icons/belok.svg',
                    value: _protCtl.text,
                    unit: 'g',
                    primary: cs.onSurface,
                    secondary: secondary,
                  ),
                ),
                Expanded(
                  child: _GoalSummaryCell(
                    iconAsset: 'assets/icons/uglevod.svg',
                    value: _carbsCtl.text,
                    unit: 'g',
                    primary: cs.onSurface,
                    secondary: secondary,
                  ),
                ),
                Expanded(
                  child: _GoalSummaryCell(
                    iconAsset: 'assets/icons/fat.svg',
                    value: _fatCtl.text,
                    unit: 'g',
                    primary: cs.onSurface,
                    secondary: secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _switchToCustom,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
            child: Text(
              l10n.goalsEditManually,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Custom-mode body ────────────────────────────────────────────
  Widget _buildCustomBody(bool isDark, ColorScheme cs, dynamic l10n) {
    final blockBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final secondary = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.goalsCustomNote,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 16 / 12,
                  color: secondary,
                ),
              ),
            ),
            GestureDetector(
              onTap: _switchToPlan,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  l10n.goalsUsePlan,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 18 / 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: blockBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                _GoalEditRow(
                  iconAsset: 'assets/icons/cal.svg',
                  label: l10n.goalCaloriesKcal,
                  controller: _calCtl,
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                const SizedBox(height: 12),
                _GoalEditRow(
                  iconAsset: 'assets/icons/belok.svg',
                  label: l10n.goalProteinG,
                  controller: _protCtl,
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                const SizedBox(height: 12),
                _GoalEditRow(
                  iconAsset: 'assets/icons/fat.svg',
                  label: l10n.goalFatG,
                  controller: _fatCtl,
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
                const SizedBox(height: 12),
                _GoalEditRow(
                  iconAsset: 'assets/icons/uglevod.svg',
                  label: l10n.goalCarbsG,
                  controller: _carbsCtl,
                  isDark: isDark,
                  primary: cs.onSurface,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownOption<T> {
  const _DropdownOption({required this.value, required this.label});
  final T value;
  final String label;
}

class _PlanDropdownRow<T> extends StatelessWidget {
  const _PlanDropdownRow({
    required this.label,
    required this.value,
    required this.options,
    required this.isDark,
    required this.primary,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_DropdownOption<T>> options;
  final bool isDark;
  final Color primary;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: primary,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: primary),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: primary,
              ),
              items: options
                  .map(
                    (o) => DropdownMenuItem<T>(
                      value: o.value,
                      child: Text(o.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanInputRow extends StatelessWidget {
  const _PlanInputRow({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.isDark,
    required this.primary,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: primary,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 70, maxWidth: 110),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkScaffold
                    : AppColors.lightScaffold,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppColors.lineDT200
                      : AppColors.lineLight200,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 18 / 14,
                  color: primary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  suffixText: suffix.isEmpty ? null : ' $suffix',
                  suffixStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: primary.withAlpha(153),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRowDivider extends StatelessWidget {
  const _PlanRowDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: isDark ? AppColors.darkDividerLight : AppColors.lightDividerLight,
    );
  }
}

class _GoalEditRow extends StatelessWidget {
  const _GoalEditRow({
    required this.iconAsset,
    required this.label,
    required this.controller,
    required this.isDark,
    required this.primary,
  });

  final String iconAsset;
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: SvgPicture.asset(iconAsset, width: 28, height: 28),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              color: primary,
            ),
          ),
        ),
        Container(
          width: 70,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.lineDT200 : AppColors.lineLight200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 18 / 14,
              color: primary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              isDense: true,
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 18 / 14,
                color: primary.withAlpha(153),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalSummaryCell extends StatelessWidget {
  const _GoalSummaryCell({
    required this.iconAsset,
    required this.value,
    required this.unit,
    required this.primary,
    required this.secondary,
  });

  final String iconAsset;
  final String value;
  final String unit;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconAsset, width: 24, height: 24),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 20 / 15,
              color: primary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 14 / 11,
            color: secondary,
          ),
        ),
      ],
    );
  }
}
