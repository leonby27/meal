import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class HeightStep extends StatefulWidget {
  final double heightCm;
  final bool isImperial;
  final ValueChanged<double> onChanged;

  const HeightStep({
    super.key,
    required this.heightCm,
    required this.isImperial,
    required this.onChanged,
  });

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  late final FixedExtentScrollController _controller;

  static const _itemExtent = 60.0;
  static const _selectedFontSize = 48.0;
  static const _unselectedFontSize = 28.0;

  // Metric: 120–220 cm
  static const _minCm = 120;
  static const _maxCm = 220;
  static const _cmCount = _maxCm - _minCm + 1;

  // Imperial: 3'11" – 7'3" (119–221 cm range in inches = 47–87 in)
  static const _minInches = 47;
  static const _maxInches = 87;
  static const _inchesCount = _maxInches - _minInches + 1;

  int get _itemCount => widget.isImperial ? _inchesCount : _cmCount;

  int _cmToInitialIndex(double cm) {
    if (widget.isImperial) {
      final totalInches = (cm / 2.54).round();
      return (totalInches - _minInches).clamp(0, _inchesCount - 1);
    }
    return (cm.round() - _minCm).clamp(0, _cmCount - 1);
  }

  String _formatImperial(int totalInches) {
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: _cmToInitialIndex(widget.heightCm),
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
            context.l10n.onboardingHeightTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingHeightHint,
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
                      final totalInches = index + _minInches;
                      widget.onChanged(totalInches * 2.54);
                    } else {
                      widget.onChanged((index + _minCm).toDouble());
                    }
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= _itemCount) return null;
                      final label = widget.isImperial
                          ? _formatImperial(index + _minInches)
                          : '${index + _minCm}';
                      final t = _fractionForIndex(index);
                      final fontSize = _unselectedFontSize +
                          (_selectedFontSize - _unselectedFontSize) * t;
                      return Center(
                        child: Text(
                          label,
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
                    childCount: _itemCount,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: Text(
              widget.isImperial ? 'ft' : context.l10n.cmUnit,
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
