import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

class AgeStep extends StatefulWidget {
  final int age;
  final ValueChanged<int> onChanged;

  const AgeStep({super.key, required this.age, required this.onChanged});

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  late final FixedExtentScrollController _controller;

  static const _itemExtent = 56.0;
  static const _wheelMaxHeight = 280.0;
  static const _wheelMinHeight = 180.0;
  // Reserved vertical space outside the wheel (emoji header + title + hint
  // + paddings). Lets LayoutBuilder pick the largest wheel that fits.
  static const _reservedNonWheelHeight = 160.0;
  static const _itemFontSize = 28.0;
  static const _firstYear = 1936;
  static const _lastYear = 2012;
  static const _yearCount = _lastYear - _firstYear + 1;

  int _yearToAge(int year) => DateTime.now().year - year;

  @override
  void initState() {
    super.initState();
    final initialYear = DateTime.now().year - widget.age;
    _controller = FixedExtentScrollController(
      initialItem: (initialYear.clamp(_firstYear, _lastYear) - _firstYear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 1.0 when the item sits in the centre slot; falls off linearly to 0
  /// as it moves outward. Drives weight + opacity transitions.
  double _fractionForIndex(int index) {
    final pixels = _controller.hasClients
        ? _controller.offset
        : _controller.initialItem * _itemExtent;
    final center = pixels / _itemExtent;
    final distance = (index - center).abs();
    return (1.0 - distance).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight - _reservedNonWheelHeight;
          final wheelHeight = math.max(
            _wheelMinHeight,
            math.min(_wheelMaxHeight, available),
          );
          return _buildContent(context, cs, wheelHeight);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme cs,
    double wheelHeight,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark ? AppColors.darkOnBack : AppColors.lightOnBack;
    final lineColor = isDark ? AppColors.lineDT100 : AppColors.lineLight100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          context.l10n.onboardingAgeTitle,
          style: onboardingTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.onboardingAgeHint,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          height: wheelHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The pill plate marking the active slot. Sits behind the
              // wheel and stays still while items scroll over it.
              Container(
                height: _itemExtent,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: lineColor),
                  boxShadow: AppColors.baseDrop,
                ),
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: _itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 2.0,
                  perspective: 0.002,
                  onSelectedItemChanged: (index) {
                    HapticFeedback.selectionClick();
                    widget.onChanged(_yearToAge(_firstYear + index));
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= _yearCount) return null;
                      final year = _firstYear + index;
                      final t = _fractionForIndex(index);
                      return Center(
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: _itemFontSize,
                            fontWeight: FontWeight.lerp(
                              FontWeight.w400,
                              FontWeight.w700,
                              t,
                            ),
                            color: Color.lerp(
                              cs.onSurfaceVariant.withAlpha(90),
                              cs.onSurface,
                              t,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _yearCount,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
