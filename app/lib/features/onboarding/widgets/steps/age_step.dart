import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class AgeStep extends StatefulWidget {
  final int age;
  final ValueChanged<int> onChanged;

  const AgeStep({super.key, required this.age, required this.onChanged});

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  late final FixedExtentScrollController _controller;

  static const _itemExtent = 60.0;
  static const _selectedFontSize = 48.0;
  static const _unselectedFontSize = 28.0;
  static const _firstYear = 1936;
  static const _lastYear = 2012;
  static const _yearCount = _lastYear - _firstYear + 1;
  static const _defaultYear = 2000;

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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            context.l10n.onboardingAgeTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingAgeHint,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              height: 200,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: _itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 1.5,
                  perspective: 0.003,
                  onSelectedItemChanged: (index) {
                    HapticFeedback.selectionClick();
                    widget.onChanged(_yearToAge(_firstYear + index));
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= _yearCount) return null;
                      final year = _firstYear + index;
                      final t = _fractionForIndex(index);
                      final fontSize = _unselectedFontSize +
                          (_selectedFontSize - _unselectedFontSize) * t;
                      return Center(
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight:
                                FontWeight.lerp(FontWeight.w400, FontWeight.w700, t),
                            color: Color.lerp(
                              cs.onSurfaceVariant.withAlpha(120),
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
            ),
          ),
          const SizedBox(height: 12),
          const Spacer(),
        ],
      ),
    );
  }
}
