import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

class RatePromptStep extends StatefulWidget {
  /// Called when the user finishes this step (either via "Rate" or "Skip").
  /// [rating] is null when skipped. [submittedReview] is true only when the
  /// native in-app review sheet was actually requested (rating ≥ 4).
  final void Function(int? rating, bool submittedReview) onCompleted;

  const RatePromptStep({super.key, required this.onCompleted});

  @override
  State<RatePromptStep> createState() => _RatePromptStepState();
}

class _RatePromptStepState extends State<RatePromptStep> {
  static const _starColor = Color(0xFFFFC93C);
  final InAppReview _inAppReview = InAppReview.instance;

  int _rating = 0;
  bool _busy = false;

  Future<void> _onRatePressed() async {
    if (_rating == 0 || _busy) return;
    setState(() => _busy = true);

    if (_rating >= 4) {
      // Native rating sheet. Apple caps this to 3 prompts/year/app per user,
      // so we don't await user input — we fire-and-forget and complete.
      try {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
        }
      } catch (_) {
        // Surface no error to the user — the prompt is best-effort.
      }
      if (!mounted) return;
      widget.onCompleted(_rating, true);
      return;
    }

    // 1–3★ — collect free-form feedback instead of routing negativity to the
    // public store listing.
    if (!mounted) return;
    final feedback = await _showFeedbackSheet(context);
    if (!mounted) return;
    debugPrint('Onboarding low-rating feedback ($_rating★): $feedback');
    widget.onCompleted(_rating, false);
  }

  Future<String?> _showFeedbackSheet(BuildContext context) async {
    final controller = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = context.l10n;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkOnBack : AppColors.lightOnBack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.onbRateFeedbackTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.onbRateFeedbackHint,
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.onbRateFeedbackSubmit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
    return result;
  }

  void _onSkipPressed() {
    if (_busy) return;
    widget.onCompleted(null, false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const NotoEmoji(name: 'star', size: 40),
          const SizedBox(height: 12),
          Text(
            context.l10n.onbRateTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onbRateSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                _Star(
                  filled: _rating >= i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = i);
                  },
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _rating == 0 || _busy ? null : _onRatePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rating == 0
                    ? (isDark
                          ? AppColors.darkDisabledBg
                          : AppColors.lightDisabledBg)
                    : AppColors.primary,
                foregroundColor: _rating == 0
                    ? (isDark
                          ? AppColors.darkDisabledContent
                          : AppColors.lightDisabledContent)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.l10n.onbRateButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _onSkipPressed,
            child: Text(
              context.l10n.onbRateSkip,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  final bool filled;
  final VoidCallback onTap;

  const _Star({required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: filled ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: _RatePromptStepState._starColor,
            size: 48,
          ),
        ),
      ),
    );
  }
}
