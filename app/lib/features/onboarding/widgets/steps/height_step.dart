import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/common/ruler_picker.dart';

class HeightStep extends StatelessWidget {
  final double heightCm;
  final bool isImperial;
  final ValueChanged<double> onChanged;

  const HeightStep({
    super.key,
    required this.heightCm,
    required this.isImperial,
    required this.onChanged,
  });

  // Metric: 120–220 cm, step 1
  static const _minCm = 120.0;
  static const _maxCm = 220.0;

  // Imperial: 47–87 in, step 1 (3'11" – 7'3")
  static const _minIn = 47.0;
  static const _maxIn = 87.0;
  static const _cmPerIn = 2.54;

  static String _formatImperial(int totalInches) {
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
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
      value: heightCm,
      min: _minCm,
      max: _maxCm,
      step: 1.0,
      tickSpacing: 12.0,
      majorTickEvery: 5,
      labelEvery: 10,
      unit: context.l10n.cmUnit,
      formatLabel: (v) => v.round().toString(),
      formatReadout: (v) => v.round().toString(),
      onChanged: onChanged,
    );
  }

  Widget _buildImperialPicker(BuildContext context) {
    final totalIn = (heightCm / _cmPerIn).round().clamp(
      _minIn.toInt(),
      _maxIn.toInt(),
    );
    return RulerPicker(
      value: totalIn.toDouble(),
      min: _minIn,
      max: _maxIn,
      step: 1.0,
      tickSpacing: 18.0,
      majorTickEvery: 6,
      labelEvery: 6,
      formatLabel: (v) => _formatImperial(v.round()),
      formatReadout: (v) => _formatImperial(v.round()),
      onChanged: (v) => onChanged(v * _cmPerIn),
    );
  }
}
