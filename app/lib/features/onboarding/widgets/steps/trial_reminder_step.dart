import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/services/subscription_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';

/// "Trial period will soon end" reminder shown right after the personal
/// plan. Pulls the yearly subscription product from
/// [SubscriptionService] so the displayed price + computed monthly use
/// the real store-formatted price (locale-correct currency symbol and
/// decimal separator) instead of hard-coded Figma copy.
class TrialReminderStep extends StatefulWidget {
  final VoidCallback onNext;

  const TrialReminderStep({super.key, required this.onNext});

  @override
  State<TrialReminderStep> createState() => _TrialReminderStepState();
}

class _TrialReminderStepState extends State<TrialReminderStep> {
  @override
  void initState() {
    super.initState();
    // Rebuild as the yearly product loads, so the price labels update
    // in place once SubscriptionService finishes its product query.
    SubscriptionService().addListener(_onSubChanged);
  }

  @override
  void dispose() {
    SubscriptionService().removeListener(_onSubChanged);
    super.dispose();
  }

  void _onSubChanged() {
    if (mounted) setState(() {});
  }

  /// Locale-aware currency formatter using the product's currency code.
  /// Falls back to USD if no product is loaded yet.
  NumberFormat _currencyFmt(BuildContext context, ProductDetails? p) {
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return NumberFormat.simpleCurrency(
      locale: localeCode,
      name: p?.currencyCode ?? 'USD',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final yearly = SubscriptionService().productById(
      SubscriptionService.yearlyId,
    );
    final fmt = _currencyFmt(context, yearly);

    // The CTA price is always 0 — trial is free.
    final trialPriceStr = fmt.format(0);
    // Use the store-formatted yearly price verbatim (it already uses
    // the platform's locale rules: "$39.99" / "39,99 €" / etc.).
    final yearlyStr = yearly?.price ?? '—';
    final monthlyStr = yearly == null
        ? '—'
        : fmt.format(yearly.rawPrice / 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            l10n.onbTrialReminderTitle,
            textAlign: TextAlign.center,
            style: onboardingTitleStyle(context, height: 32 / 24),
          ),
          const Spacer(),
          // Bell hero illustration. Source is 1240x1240 @4.0x.
          SizedBox(
            width: 196,
            height: 196,
            child: Image.asset(
              'assets/onboarding/bell.jpg',
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          // ✓ No payment required now
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/onboarding/icons/check.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.onbTrialReminderNoPaymentNow,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Primary CTA — full width.
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              // CTA only advances to the next onboarding step (the real
              // paywall handles purchase). Don't gate on IAP product
              // load — Android APKs without a Play billing connection
              // would otherwise show a permanently-disabled button.
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.onbTrialReminderCta(trialPriceStr),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle below the button: yearly + computed monthly.
          Text(
            l10n.onbTrialReminderSubtitle(yearlyStr, monthlyStr),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 18 / 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
