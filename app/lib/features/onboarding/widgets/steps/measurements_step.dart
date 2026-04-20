import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';

class MeasurementsStep extends StatefulWidget {
  final double heightCm;
  final double weightKg;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;

  const MeasurementsStep({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.onHeightChanged,
    required this.onWeightChanged,
  });

  @override
  State<MeasurementsStep> createState() => _MeasurementsStepState();
}

class _MeasurementsStepState extends State<MeasurementsStep> {
  late final FixedExtentScrollController _heightController;
  late final FixedExtentScrollController _weightController;

  static const _itemExtent = 50.0;
  static const _selectedFontSize = 36.0;
  static const _unselectedFontSize = 22.0;

  @override
  void initState() {
    super.initState();
    _heightController = FixedExtentScrollController(
      initialItem: widget.heightCm.round() - 120,
    );
    _weightController = FixedExtentScrollController(
      initialItem: ((widget.weightKg - 30.0) / 0.5).round(),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double _fractionForIndex(int index, FixedExtentScrollController controller) {
    final pixels = controller.hasClients
        ? controller.offset
        : controller.initialItem * _itemExtent;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            context.l10n.onboardingMeasurementsTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                _buildPickerSection(
                  label: context.l10n.heightLabel,
                  unit: context.l10n.cmUnit,
                  controller: _heightController,
                  itemCount: 101,
                  itemBuilder: (index) => '${index + 120}',
                  onChanged: (index) =>
                      widget.onHeightChanged((index + 120).toDouble()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: cs.outline),
                ),
                _buildPickerSection(
                  label: context.l10n.currentWeightLabel,
                  unit: context.l10n.kgUnit,
                  controller: _weightController,
                  itemCount: 341,
                  itemBuilder: (index) =>
                      (30.0 + index * 0.5).toStringAsFixed(1),
                  onChanged: (index) =>
                      widget.onWeightChanged(30.0 + index * 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerSection({
    required String label,
    required String unit,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: _itemExtent,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: 1.5,
                perspective: 0.003,
                onSelectedItemChanged: (index) {
                  HapticFeedback.selectionClick();
                  onChanged(index);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index >= itemCount) return null;
                    final text = itemBuilder(index);
                    final t = _fractionForIndex(index, controller);
                    final fontSize = _unselectedFontSize +
                        (_selectedFontSize - _unselectedFontSize) * t;
                    return Center(
                      child: Text(
                        text,
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
                  childCount: itemCount,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            unit,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
