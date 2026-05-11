import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/services/tdee_calculator.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

class WeightLossSpeedStep extends StatelessWidget {
  final String goal;
  final double currentWeightKg;
  final double targetWeightKg;
  final double kgPerWeek;
  final bool isImperial;
  final ValueChanged<double> onChanged;

  const WeightLossSpeedStep({
    super.key,
    required this.goal,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.kgPerWeek,
    required this.isImperial,
    required this.onChanged,
  });

  static const double _kgToLb = 2.20462;

  /// Goal-specific slider scale. Range is chosen so the recommended
  /// pace sits at the EXACT centre of the track (so the thumb starts
  /// visually centred). Lose: 0.1-0.9 kg/wk, centre 0.5. Gain: 0.1-0.5
  /// kg/wk, centre 0.3 — natural muscle synthesis tops out around
  /// 0.5 kg/week even for novices.
  ({double min, double max, double recommended, double alertThreshold})
      _scaleFor(String goal) {
    if (goal == 'gain') {
      return (min: 0.1, max: 0.5, recommended: 0.3, alertThreshold: 0.4);
    }
    return (min: 0.1, max: 0.9, recommended: 0.5, alertThreshold: 0.7);
  }

  /// Hero readout split into a big number and a small unit label,
  /// e.g. "0.5" + " kg" so the unit can render at 16sp next to the
  /// 40sp number.
  ({String number, String unit}) _readoutParts(double kg) {
    if (isImperial) {
      final lb = (kg * _kgToLb).toStringAsFixed(1);
      return (number: lb, unit: ' lb');
    }
    return (number: kg.toStringAsFixed(1), unit: ' kg');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    final scale = _scaleFor(goal);
    final divisions = ((scale.max - scale.min) * 10).round();
    final clamped = kgPerWeek.clamp(scale.min, scale.max).toDouble();
    final targetDate = TdeeCalculator.estimateTargetDate(
      currentWeight: currentWeightKg,
      targetWeight: targetWeightKg,
      goal: goal,
      weightLossKgPerWeek: clamped,
    );
    final dateFormatted = DateFormat.yMMMd(localeCode).format(targetDate);
    final title = goal == 'gain' ? l10n.onbSpeedTitleGain : l10n.onbSpeedTitleLose;
    final recommendedRate = isImperial
        ? (scale.recommended * _kgToLb).toStringAsFixed(1)
        : scale.recommended.toStringAsFixed(1);
    final hint = isImperial
        ? l10n.onbSpeedHintLb(recommendedRate)
        : l10n.onbSpeedHintKg(recommendedRate);
    final readout = _readoutParts(clamped);
    final isAlert = clamped > scale.alertThreshold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const NotoEmoji(name: 'high-voltage', size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: onboardingTitleStyle(context, height: 32 / 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              height: 18 / 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Big rate readout: 0.5 kg
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: readout.number,
                  style: onboardingTitleStyle(
                    context,
                    fontSize: 40,
                    height: 32 / 40,
                  ),
                ),
                TextSpan(
                  text: readout.unit,
                  style: onboardingTitleStyle(
                    context,
                    fontSize: 16,
                    height: 32 / 16,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.lineLight300,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withAlpha(40),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
              ),
              // Track spans the full slider width so its edges line up
              // with the leading edge of "Slow" and trailing edge of
              // "Fast" below.
              trackShape: const _FullWidthTrackShape(),
            ),
            child: Slider(
              value: clamped,
              min: scale.min,
              max: scale.max,
              divisions: divisions,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                final snapped = (v * 10).round() / 10.0;
                onChanged(snapped);
              },
            ),
          ),
          const SizedBox(height: 4),
          // Three labels below the slider, evenly spaced.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SliderLabel(l10n.onbSpeedSlow),
                _SliderLabel(l10n.onbSpeedBalanced),
                _SliderLabel(l10n.onbSpeedFast),
              ],
            ),
          ),
          const Spacer(),
          _OutcomeCard(
            isAlert: isAlert,
            // Date always reflects the currently selected pace — only
            // the icon and supporting copy switch between good/alert.
            title: l10n.onbSpeedGoodTitle(dateFormatted),
            body: isAlert
                ? l10n.onbSpeedAlertBody
                : l10n.onbSpeedGoodBody,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SliderLabel extends StatelessWidget {
  final String text;
  const _SliderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 16 / 13,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

/// Slider track inset 8px from each edge of the slider's parent box.
/// Aligns roughly with the leading edge of the "Slow" label and the
/// trailing edge of "Fast" below, while leaving a small breathing
/// margin on each side.
class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  static const double _edgeInset = 8;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx + _edgeInset,
      trackTop,
      parentBox.size.width - _edgeInset * 2,
      trackHeight,
    );
  }
}

/// Bottom card: green-check / orange-alert icon plus a copy that
/// reflects the user's currently selected pace. The title is forced
/// to a single line via `maxLines: 1` + `overflow: ellipsis`; copy in
/// every supported locale was sized to fit at 15sp Inter.
class _OutcomeCard extends StatelessWidget {
  final bool isAlert;
  final String title;
  final String body;

  const _OutcomeCard({
    required this.isAlert,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            isAlert
                ? 'assets/onboarding/icons/alert.svg'
                : 'assets/onboarding/icons/good.svg',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 20 / 15,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 14 / 12,
                    color: cs.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

