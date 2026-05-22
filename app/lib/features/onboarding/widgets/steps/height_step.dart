import 'package:flutter/material.dart';

import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/common/vertical_ruler_picker.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            context.l10n.onboardingHeightTitle,
            style: onboardingTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingHeightHint,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Vertical ruler grows to fill the remaining vertical space —
          // important so the readout sits comfortably centred between
          // the title block above and the CTA below.
          Expanded(
            child: isImperial
                ? _buildImperialPicker(context)
                : _buildMetricPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPicker(BuildContext context) {
    return VerticalRulerPicker(
      value: heightCm,
      min: _minCm,
      max: _maxCm,
      step: 1.0,
      tickSpacing: 8.0,
      majorTickEvery: 10,
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
    return VerticalRulerPicker(
      value: totalIn.toDouble(),
      min: _minIn,
      max: _maxIn,
      step: 1.0,
      tickSpacing: 10.0,
      majorTickEvery: 6,
      labelEvery: 6,
      formatLabel: (v) => _formatImperial(v.round()),
      formatReadout: (v) => _formatImperial(v.round()),
      onChanged: (v) => onChanged(v * _cmPerIn),
    );
  }
}
