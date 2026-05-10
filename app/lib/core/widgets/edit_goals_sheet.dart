import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/database/app_database.dart';
import 'package:meal_tracker/core/services/login_sync_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

/// Bottom sheet that edits the four daily nutrition goals
/// (calories, protein, fat, carbs) and persists them to the local
/// settings store + cloud sync. Pops with `true` on save.
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
  late final TextEditingController _calCtl;
  late final TextEditingController _protCtl;
  late final TextEditingController _fatCtl;
  late final TextEditingController _carbsCtl;
  bool _saving = false;
  // Re-entry guard for the bidirectional cal ↔ P/F/C sync.
  bool _syncing = false;

  // Onboarding macro split: 30% protein / 25% fat / 45% carbs of total
  // kcal. Mirrors `TdeeCalculator`. Atwater conversion: P,C = 4 kcal/g;
  // F = 9 kcal/g.
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
    _calCtl.addListener(_onCaloriesChanged);
    _protCtl.addListener(_onMacrosChanged);
    _fatCtl.addListener(_onMacrosChanged);
    _carbsCtl.addListener(_onMacrosChanged);
  }

  @override
  void dispose() {
    _calCtl
      ..removeListener(_onCaloriesChanged)
      ..dispose();
    _protCtl
      ..removeListener(_onMacrosChanged)
      ..dispose();
    _fatCtl
      ..removeListener(_onMacrosChanged)
      ..dispose();
    _carbsCtl
      ..removeListener(_onMacrosChanged)
      ..dispose();
    super.dispose();
  }

  void _setSilently(TextEditingController ctl, String value) {
    if (ctl.text == value) return;
    ctl.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

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

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = await AppDatabase.getInstance();
    final goals = {
      'calorie_goal': _calCtl.text,
      'protein_goal': _protCtl.text,
      'fat_goal': _fatCtl.text,
      'carbs_goal': _carbsCtl.text,
    };
    for (final entry in goals.entries) {
      await db.setSetting(entry.key, entry.value);
    }
    unawaited(LoginSyncService().pushSettings(goals));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final sheetBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final blockBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final closeBtnBg =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: DecoratedBox(
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    onPressed: _saving ? null : _save,
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
      ),
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
