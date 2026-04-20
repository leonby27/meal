import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class TargetWeightStep extends StatefulWidget {
  final double targetWeight;
  final String? goal;
  final bool isImperial;
  final ValueChanged<double> onChanged;

  const TargetWeightStep({
    super.key,
    required this.targetWeight,
    required this.goal,
    required this.isImperial,
    required this.onChanged,
  });

  @override
  State<TargetWeightStep> createState() => _TargetWeightStepState();
}

class _TargetWeightStepState extends State<TargetWeightStep> {
  late final FixedExtentScrollController _controller;

  static const _itemExtent = 60.0;
  static const _selectedFontSize = 48.0;
  static const _unselectedFontSize = 28.0;

  // Metric: 30–200 kg, step 0.5
  static const _minKg = 30.0;
  static const _maxKg = 200.0;
  static const _kgStep = 0.5;
  static final _kgCount = ((_maxKg - _minKg) / _kgStep).round() + 1;

  // Imperial: 66–440 lb, step 1
  static const _minLb = 66;
  static const _maxLb = 440;
  static const _lbCount = _maxLb - _minLb + 1;

  static const _kgToLb = 2.20462;

  int get _itemCount => widget.isImperial ? _lbCount : _kgCount;

  int _initialIndex() {
    if (widget.isImperial) {
      final lb = (widget.targetWeight * _kgToLb).round();
      return (lb - _minLb).clamp(0, _lbCount - 1);
    }
    return ((widget.targetWeight - _minKg) / _kgStep).round().clamp(0, _kgCount - 1);
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _initialIndex());
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

  String? _hint(BuildContext context) {
    switch (widget.goal) {
      case 'lose':
        return context.l10n.safeWeightLossPace;
      case 'gain':
        return context.l10n.recommendedWeightGainPace;
      default:
        return null;
    }
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
            context.l10n.onboardingTargetWeightTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingTargetWeightHint,
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
                    if (widget.isImperial) {
                      final lb = index + _minLb;
                      widget.onChanged(lb / _kgToLb);
                    } else {
                      widget.onChanged(_minKg + index * _kgStep);
                    }
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= _itemCount) return null;
                      final label = widget.isImperial
                          ? '${index + _minLb}'
                          : (_minKg + index * _kgStep).toStringAsFixed(1);
                      final t = _fractionForIndex(index);
                      final fontSize = _unselectedFontSize +
                          (_selectedFontSize - _unselectedFontSize) * t;
                      return Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.lerp(
                                FontWeight.w400, FontWeight.w700, t),
                            color: Color.lerp(
                              cs.onSurfaceVariant.withAlpha(120),
                              cs.onSurface,
                              t,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _itemCount,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: Text(
              widget.isImperial ? 'lb' : context.l10n.kgUnit,
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          if (_hint(context) != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                _hint(context)!,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
