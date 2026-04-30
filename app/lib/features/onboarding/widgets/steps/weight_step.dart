import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/common/ruler_picker.dart';

class WeightStep extends StatelessWidget {
  final double weightKg;
  final bool isImperial;
  final ValueChanged<double> onChanged;

  const WeightStep({
    super.key,
    required this.weightKg,
    required this.isImperial,
    required this.onChanged,
  });

  // Metric: 30–200 kg, snap step 0.5
  static const _minKg = 30.0;
  static const _maxKg = 200.0;
  static const _kgStep = 0.5;

  // Imperial: 66–440 lb, snap step 1
  static const _minLb = 66.0;
  static const _maxLb = 440.0;
  static const _lbStep = 1.0;
  static const _kgToLb = 2.20462;

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
            context.l10n.onboardingWeightTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingWeightHint,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          if (isImperial)
            _buildImperialPicker(context)
          else
            _buildMetricPicker(context),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMetricPicker(BuildContext context) {
    return RulerPicker(
      value: weightKg,
      min: _minKg,
      max: _maxKg,
      step: _kgStep,
      tickSpacing: 8.0,
      majorTickEvery: 10,
      labelEvery: 10,
      unit: context.l10n.kgUnit,
      formatLabel: (v) => v.round().toString(),
      formatReadout: (v) {
        final rounded = (v * 10).round() / 10.0;
        return rounded == rounded.roundToDouble()
            ? rounded.toStringAsFixed(0)
            : rounded.toStringAsFixed(1);
      },
      onChanged: onChanged,
    );
  }

  Widget _buildImperialPicker(BuildContext context) {
    final lb = (weightKg * _kgToLb).clamp(_minLb, _maxLb);
    return RulerPicker(
      value: lb.toDouble(),
      min: _minLb,
      max: _maxLb,
      step: _lbStep,
      tickSpacing: 8.0,
      majorTickEvery: 10,
      labelEvery: 10,
      unit: 'lb',
      formatLabel: (v) => v.round().toString(),
      formatReadout: (v) => v.round().toString(),
      onChanged: (v) => onChanged(v / _kgToLb),
    );
  }
}
