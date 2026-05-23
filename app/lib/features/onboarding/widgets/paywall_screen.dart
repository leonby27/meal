import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/api/api_client.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
import 'package:meal_tracker/core/services/entitlement_service.dart';
import 'package:meal_tracker/core/services/subscription_service.dart';
import 'package:meal_tracker/core/utils/l10n_extension.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_noto_emoji.dart';
import 'package:meal_tracker/features/onboarding/widgets/steps/_title_style.dart';
import 'package:meal_tracker/features/onboarding/widgets/common/faq_card.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  static const _termsUrl = 'https://leonby27.github.io/meal/terms-of-use.html';
  static const _privacyUrl =
      'https://leonby27.github.io/meal/privacy-policy.html';

  /// Brand blue for the selected plan border + checkbox. Hardcoded to the
  /// Figma value rather than `AppColors.primary` — the design uses a slightly
  /// different shade specifically for this paywall.
  static const Color _brandBlue = Color(0xFF094ABE);

  /// Neutral card bg used by every secondary block on this screen (plan
  /// cards, trial countdown, feature list, FAQ).
  static const Color _cardBg = Color(0xFFF5F6F8);

  /// Pill-icon bg used by the header back / kebab pills.
  static const Color _pillBg = Color(0xFFF5F6F8);

  /// Body text color — Figma `#0A1B39` (same as AppColors.lightOnSurface).
  static const Color _ink = Color(0xFF0A1B39);

  /// Secondary text — Figma `#676E85`.
  static const Color _muted = Color(0xFF676E85);

  /// Tertiary text — Figma `#83899F`. Used for the price suffix in the
  /// trial countdown row.
  static const Color _faint = Color(0xFF83899F);

  int _selectedPlan = 1; // yearly pre-selected
  late final AnimationController _enterController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  StreamSubscription<SubEvent>? _eventsSub;

  // Funnel telemetry state.
  // - `_loggedViewItemList`: standard `view_item_list` must fire exactly
  //   once per paywall mount, but the products that feed it usually
  //   aren't loaded yet at initState (SubscriptionService boots lazily).
  //   We wait for the first ready state and gate via this flag.
  // - `_purchaseSucceededOnScreen`: distinguishes a successful close
  //   ("purchased") from a backgrounded close ("abandoned") in dispose().
  bool _loggedViewItemList = false;
  bool _purchaseSucceededOnScreen = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
        );
    _enterController.forward();

    AuthService().addListener(_onAuthChanged);

    final sub = SubscriptionService();
    sub.addListener(_onStateChanged);
    _eventsSub = sub.events.listen(_onSubEvent);

    unawaited(
      AnalyticsService.instance.logPaywallView(
        planId: _planIdForIndex(_selectedPlan),
      ),
    );

    // If products are already cached from a previous mount we can fire
    // the standard `view_item_list` immediately; otherwise [_onStateChanged]
    // will catch the transition into ready and fire it then.
    _maybeLogViewItemList();

    sub.ensureProductsLoaded();
  }

  String _planIdForIndex(int idx) =>
      idx == 1 ? SubscriptionService.yearlyId : SubscriptionService.weeklyId;

  /// Builds an [AnalyticsEventItem] for one of our subscription products.
  /// Returning `null` when the product hasn't loaded keeps callers free of
  /// scattered null-checks.
  AnalyticsEventItem? _itemFor(ProductDetails? p) {
    if (p == null) return null;
    return AnalyticsEventItem(
      itemId: p.id,
      itemName: p.title.isNotEmpty ? p.title : p.id,
      itemCategory: 'subscription',
      itemVariant: p.id == SubscriptionService.yearlyId ? 'yearly' : 'weekly',
      price: p.rawPrice,
      currency: p.currencyCode,
      quantity: 1,
    );
  }

  /// Fires `view_item_list` the first time both products are loaded. The
  /// standard ecommerce event drives Firebase's product-list funnel and
  /// Google Ads conversion attribution for paywall impressions.
  void _maybeLogViewItemList() {
    if (_loggedViewItemList) return;
    final items = [
      _itemFor(_yearlyProduct),
      _itemFor(_weeklyProduct),
    ].whereType<AnalyticsEventItem>().toList();
    if (items.isEmpty) return;
    _loggedViewItemList = true;
    unawaited(
      AnalyticsService.instance.logViewItemList(
        items: items,
        itemListId: 'paywall',
        itemListName: 'Onboarding Paywall',
      ),
    );
  }

  void _onAuthChanged() {
    if (AuthService().isPremium && mounted) {
      context.go('/diary');
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
    // Products often finish loading after initState — re-check on every
    // state change until we've sent the impression once.
    _maybeLogViewItemList();
  }

  void _onSubEvent(SubEvent event) {
    if (!mounted) return;
    final l = context.l10n;

    final selectedPlanId = _planIdForIndex(_selectedPlan);

    switch (event) {
      case StoreUnavailableEvent():
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_failed',
            parameters: {
              'plan': selectedPlanId,
              'reason': 'store_unavailable',
            },
          ),
        );
        _showErrorDialog(l.paywallErrorStoreUnavailable);
      case ProductsEmptyEvent():
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_failed',
            parameters: {
              'plan': selectedPlanId,
              'reason': 'products_empty',
            },
          ),
        );
        _showErrorDialog(l.paywallErrorProductsEmpty);
      case ProductsLoadFailedEvent(details: final d):
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_failed',
            parameters: {
              'plan': selectedPlanId,
              'reason': 'products_load_failed',
            },
          ),
        );
        _showErrorDialog(l.paywallErrorQueryFailed, debugDetails: d);
      case PurchaseFailedEvent(details: final d):
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_failed',
            parameters: {
              'plan': selectedPlanId,
              'reason': 'purchase_failed',
            },
          ),
        );
        _showErrorDialog(l.paywallErrorPurchaseFailed, debugDetails: d);
      case PaymentPendingEvent():
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_pending',
            parameters: {'plan': selectedPlanId},
          ),
        );
        _showErrorDialog(l.paywallErrorPaymentPending, showRetry: false);
      case PurchaseCanceledEvent():
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_canceled',
            parameters: {'plan': selectedPlanId},
          ),
        );
      case PurchaseSuccessEvent():
        _purchaseSucceededOnScreen = true;
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_purchase_success',
            parameters: {
              'plan': selectedPlanId,
              'has_trial': _selectedPlanHasTrial ? 1 : 0,
            },
          ),
        );
      case RestoreCompletedEvent(foundActive: final found):
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_restore_completed',
            parameters: {'found_active': found ? 1 : 0},
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              found ? l.paywallRestoreSuccess : l.paywallRestoreNotFound,
            ),
          ),
        );
      case RestoreFailedEvent(details: final d):
        unawaited(
          AnalyticsService.instance.logEvent(
            'paywall_restore_failed',
          ),
        );
        _showErrorDialog(l.paywallErrorRestoreFailed, debugDetails: d);
    }
  }

  @override
  void dispose() {
    // The paywall is the last step of the onboarding funnel — knowing
    // whether the screen was left because the user converted, restored
    // a prior purchase, or simply backgrounded the app is essential for
    // the abandonment rate. AuthService.isPremium covers the silent
    // restore case (premium flipped without us seeing PurchaseSuccess).
    final purchased = _purchaseSucceededOnScreen || AuthService().isPremium;
    unawaited(
      AnalyticsService.instance.logEvent(
        'paywall_exited',
        parameters: {
          'reason': purchased ? 'purchased' : 'abandoned',
          'plan': _planIdForIndex(_selectedPlan),
        },
      ),
    );

    AuthService().removeListener(_onAuthChanged);
    SubscriptionService().removeListener(_onStateChanged);
    _eventsSub?.cancel();
    _enterController.dispose();
    super.dispose();
  }

  void _selectPlan(int index) {
    if (_selectedPlan == index) return;
    setState(() => _selectedPlan = index);
    final productId = _planIdForIndex(index);
    final item = _itemFor(SubscriptionService().productById(productId));
    if (item != null) {
      unawaited(
        AnalyticsService.instance.logSelectItem(
          items: [item],
          itemListId: 'paywall',
          itemListName: 'Onboarding Paywall',
        ),
      );
    }
    unawaited(
      AnalyticsService.instance.logEvent(
        'paywall_plan_selected',
        parameters: {
          'plan': productId,
          'has_trial': productId == SubscriptionService.yearlyId ? 1 : 0,
        },
      ),
    );
  }

  ProductDetails? get _weeklyProduct =>
      SubscriptionService().productById(SubscriptionService.weeklyId);

  ProductDetails? get _yearlyProduct =>
      SubscriptionService().productById(SubscriptionService.yearlyId);

  bool get _selectedPlanIsYearly => _selectedPlan == 1;

  bool get _selectedPlanHasTrial => _selectedPlanIsYearly;

  ProductDetails? get _selectedProduct =>
      _selectedPlanIsYearly ? _yearlyProduct : _weeklyProduct;

  bool _productsLoadFailed(SubscriptionService sub) =>
      sub.state == SubState.noProducts || sub.state == SubState.unavailable;

  bool _productsAreLoading(SubscriptionService sub) =>
      sub.state == SubState.initializing ||
      (sub.state == SubState.idle && sub.products.isEmpty);

  String _weeklyPriceLabel(SubscriptionService sub) {
    final p = _weeklyProduct;
    if (p == null && _productsLoadFailed(sub)) return '—';
    if (p == null) return context.l10n.paywallLoadingPrice;
    return '${p.price} / ${context.l10n.paywallPerWeek}';
  }

  String _yearlyPriceLabel(SubscriptionService sub) {
    final p = _yearlyProduct;
    if (p == null && _productsLoadFailed(sub)) return '—';
    if (p == null) return context.l10n.paywallLoadingPrice;
    return '${p.price} / ${context.l10n.paywallPerYear}';
  }

  Future<void> _subscribe() async {
    final sub = SubscriptionService();
    if (sub.products.isEmpty) return;

    final productId = _selectedPlan == 0
        ? SubscriptionService.weeklyId
        : SubscriptionService.yearlyId;

    final product = sub.productById(productId);
    if (product == null) {
      unawaited(
        AnalyticsService.instance.logEvent(
          'paywall_purchase_failed',
          parameters: {
            'plan': productId,
            'reason': 'selected_product_unavailable',
          },
        ),
      );
      _showErrorDialog(context.l10n.paywallErrorSelectedProductUnavailable);
      return;
    }

    // Custom CTA-click event captures the funnel even if the user backs
    // out of the platform purchase sheet before any StoreKit/Play event
    // fires.
    unawaited(
      AnalyticsService.instance.logEvent(
        'paywall_cta_clicked',
        parameters: {
          'plan': productId,
          'has_trial': _selectedPlanHasTrial ? 1 : 0,
        },
      ),
    );

    // Standard ecommerce event — feeds Firebase's Begin-Checkout funnel
    // and Google Ads conversion events.
    final item = _itemFor(product);
    if (item != null) {
      unawaited(
        AnalyticsService.instance.logBeginCheckout(
          value: product.rawPrice,
          currency: product.currencyCode,
          items: [item],
        ),
      );
    }

    await sub.buy(product);
  }

  void _restore() {
    unawaited(
      AnalyticsService.instance.logEvent('paywall_restore_clicked'),
    );
    SubscriptionService().restore();
  }

  Future<void> _redeemCode() async {
    if (!mounted) return;
    unawaited(AnalyticsService.instance.logEvent('paywall_promo_opened'));
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PromoCodeSheet(),
    );
    if (code == null || !mounted) {
      unawaited(
        AnalyticsService.instance.logEvent('paywall_promo_dismissed'),
      );
      return;
    }

    unawaited(AnalyticsService.instance.logEvent('paywall_promo_submitted'));

    // Snapshot localized strings before the await so we can read them
    // safely in the catch blocks without crossing the async gap.
    final invalidCopy = context.l10n.promoCodeInvalid;
    final networkCopy = context.l10n.networkGenericError;

    String? errorText;
    String? failureReason;
    try {
      await EntitlementService().redeemPromo(code.trim());
    } on ApiException catch (e) {
      // 404 from /api/iap/promo/redeem = code not in the allow-list.
      // Anything else (5xx, timeout) is a server problem, not the user's.
      if (e.statusCode == 404) {
        errorText = invalidCopy;
        failureReason = 'invalid';
      } else {
        errorText = networkCopy;
        failureReason = 'network';
      }
    } catch (_) {
      errorText = networkCopy;
      failureReason = 'network';
    }
    if (errorText == null) {
      _purchaseSucceededOnScreen = true;
      unawaited(
        AnalyticsService.instance.logEvent('paywall_promo_succeeded'),
      );
    } else {
      unawaited(
        AnalyticsService.instance.logEvent(
          'paywall_promo_failed',
          parameters: {'reason': failureReason ?? 'unknown'},
        ),
      );
    }
    if (!mounted || errorText == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorText)));
  }

  Future<void> _showErrorDialog(
    String message, {
    String? debugDetails,
    bool showRetry = true,
  }) async {
    if (!mounted) return;
    final l = context.l10n;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.paywallErrorTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (kDebugMode && debugDetails != null) ...[
                const SizedBox(height: 12),
                Text(
                  debugDetails,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.close),
            ),
            if (showRetry)
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  SubscriptionService().retryProductsLoading();
                },
                child: Text(l.paywallTryAgain),
              ),
          ],
        );
      },
    );
  }

  void _openTerms() {
    unawaited(
      AnalyticsService.instance.logEvent('paywall_terms_opened'),
    );
    launchUrl(Uri.parse(_termsUrl), mode: LaunchMode.externalApplication);
  }

  void _openPrivacy() {
    unawaited(
      AnalyticsService.instance.logEvent('paywall_privacy_opened'),
    );
    launchUrl(Uri.parse(_privacyUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // The free-trial path has been removed — paywall is always the
    // single gate between non-premium users and the app. No back, no
    // skip; the only ways out are buy, redeem a promo, or quit.
    const canGoBack = false;
    final sub = SubscriptionService();
    final l = context.l10n;

    final canSubscribe =
        sub.state == SubState.ready && _selectedProduct != null;
    final isPurchasing = sub.state == SubState.purchasing;
    final isLoading = _productsAreLoading(sub);
    final canRetry = _productsLoadFailed(sub);

    final VoidCallback? ctaHandler = isPurchasing
        ? null
        : canSubscribe
        ? _subscribe
        : canRetry
        ? SubscriptionService().retryProductsLoading
        : null;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        backgroundColor: AppColors.lightBack3,
        body: Stack(
          children: [
            FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  children: [
                    _PaywallHeader(
                      // No back arrow — paywall is the only exit gate from
                      // onboarding for non-premium users. Kept the param so
                      // the header can grow a back button later if needed.
                      onBack: null,
                      onRestore: _restore,
                      onTerms: _openTerms,
                      onPrivacy: _openPrivacy,
                      onCode: _redeemCode,
                      onRestart: () => AuthService().resetOnboarding(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title.
                            Text(
                              l.paywallContinuePro,
                              textAlign: TextAlign.center,
                              style: onboardingTitleStyle(
                                context,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Plan picker.
                            _PlanPicker(
                              selected: _selectedPlan,
                              weeklyPrice: _weeklyPriceLabel(sub),
                              yearlyPrice: _yearlyPriceLabel(sub),
                              weeklyLabel: l.paywallMonthly,
                              yearlyLabel: l.paywallYearly,
                              save85Label: l.paywallSave85,
                              trialBadgeLabel: l.paywallTrialBadge,
                              brandBlue: _brandBlue,
                              cardBg: _cardBg,
                              ink: _ink,
                              muted: _muted,
                              onSelect: _selectPlan,
                            ),
                            const SizedBox(height: 16),

                            // Trial countdown — only when yearly (with trial).
                            // AnimatedCrossFade animates size and opacity on
                            // the SAME curve/duration, so the card fades and
                            // collapses (or appears and expands) in lockstep.
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 260),
                              sizeCurve: Curves.easeOutCubic,
                              firstCurve: Curves.easeOutCubic,
                              secondCurve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              crossFadeState: _selectedPlanHasTrial
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              firstChild: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _TrialCountdown(
                                  cardBg: _cardBg,
                                  ink: _ink,
                                  faint: _faint,
                                  day1Label: l.paywallDayPrefix(1),
                                  day3Label: l.paywallDayPrefix(3),
                                  day4Label: l.paywallDayPrefix(4),
                                  trialStarts: l.paywallTrialStarts,
                                  remindYou: l.paywallTrialRemindYou,
                                  planBegins: l.paywallTrialPlanBegins,
                                  planPriceSuffix: _yearlyProduct == null
                                      ? ''
                                      : ' · ${_yearlyProduct!.price}/${l.paywallPerYear}',
                                ),
                              ),
                              secondChild: const SizedBox(
                                width: double.infinity,
                                height: 0,
                              ),
                            ),

                            // Feature bullets.
                            _FeaturesCard(
                              cardBg: _cardBg,
                              ink: _ink,
                              features: [
                                (emoji: 'camera-with-flash', text: l.paywallFeatureSnap),
                                (emoji: 'hundred-points', text: l.paywallFeatureScore),
                                (emoji: 'bullseye', text: l.paywallFeatureTags),
                                (emoji: 'locked', text: l.paywallFeaturePrivacy),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // FAQ.
                            FaqCard(
                              header: l.resultFaqHeader,
                              background: _cardBg,
                              items: [
                                (
                                  question: l.resultFaqCancelQ,
                                  answer:
                                      Theme.of(context).platform ==
                                          TargetPlatform.iOS
                                      ? l.resultFaqCancelAIos
                                      : l.resultFaqCancelAAndroid,
                                ),
                                (
                                  question: l.resultFaqSecurityQ,
                                  answer: l.resultFaqSecurityA,
                                ),
                                (
                                  question: l.resultFaqTrialQ,
                                  answer: l.resultFaqTrialA,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Bottom block sits in the Column rather than as a
                    // Stack-pinned overlay so the scroll viewport ends
                    // exactly at its top edge — no white gap when the
                    // content is shorter than the screen (e.g. weekly
                    // selected, no trial countdown card).
                    _BottomBar(
                      showNoPayment: _selectedPlanHasTrial,
                      ctaLabel: _ctaLabel(),
                      ctaEnabled: ctaHandler != null && !isLoading,
                      isBusy: isPurchasing || isLoading,
                      noPaymentLabel: l.paywallNoPaymentNow,
                      disclaimer: l.paywallHardDisclaimer,
                      onCta: ctaHandler,
                      ink: _ink,
                      muted: _muted,
                    ),
                  ],
                ),
              ),
            ),

            if (sub.state == SubState.restoring)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  String _ctaLabel() {
    final l = context.l10n;
    if (_productsLoadFailed(SubscriptionService())) return l.paywallTryAgain;
    // Yearly plan ships with a free trial — show the trial-flavoured CTA.
    // Weekly plan has no trial; the casual "Let's go" reads as a softer
    // commitment than the formal "Subscribe" label.
    if (_selectedPlanHasTrial) return l.paywallStartTrial;
    return l.paywallGo;
  }
}

// ---------------------------------------------------------------------------
// Header strip: white panel with rounded bottom corners, drop shadow,
// holding the back-arrow pill (hidden when canPop is false) and the
// kebab menu pill.
// ---------------------------------------------------------------------------
class _PaywallHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback onCode;
  final VoidCallback onRestart;

  const _PaywallHeader({
    required this.onBack,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
    required this.onCode,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    // Figma calls for 108 high with the icons sitting 56 from the top of
    // the screen. We anchor the pill row to the safe-area top + 12 so it
    // looks consistent across devices regardless of notch height.
    final headerHeight = topInset + 56;

    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        color: AppColors.lightOnBack,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: AppColors.baseDrop,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset + 6, left: 16, right: 16),
        child: Row(
          children: [
            if (onBack != null)
              _PillIconButton(
                icon: Icons.arrow_back,
                iconSize: 24,
                onTap: onBack,
              )
            else
              const SizedBox(width: 46, height: 36),
            const Spacer(),
            _MenuKebab(
              onRestore: onRestore,
              onTerms: onTerms,
              onPrivacy: onPrivacy,
              onCode: onCode,
              onRestart: onRestart,
            ),
          ],
        ),
      ),
    );
  }
}

/// 46×36 rounded pill used by the header back/kebab buttons.
class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;

  const _PillIconButton({
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 36,
        decoration: BoxDecoration(
          color: _PaywallScreenState._pillBg,
          borderRadius: BorderRadius.circular(122),
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: _PaywallScreenState._ink,
          ),
        ),
      ),
    );
  }
}

/// Wraps the kebab pill in a [PopupMenuButton] so tapping opens the
/// existing menu (restore / terms / privacy / code / restart).
class _MenuKebab extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback onCode;
  final VoidCallback onRestart;

  const _MenuKebab({
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
    required this.onCode,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lineLight100),
      ),
      offset: const Offset(0, 44),
      tooltip: '',
      padding: EdgeInsets.zero,
      // Soften Material's default snap-in.
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 240),
        reverseDuration: Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      // PopupMenuButton wraps its child in an InkWell — keep the pill
      // shape intact by removing internal padding.
      child: const _PillIconButton(
        icon: Icons.more_vert,
        iconSize: 20,
        onTap: null,
      ),
      onSelected: (value) {
        switch (value) {
          case 'restore':
            onRestore();
          case 'terms':
            onTerms();
          case 'privacy':
            onPrivacy();
          case 'code':
            onCode();
          case 'restart':
            onRestart();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'restore',
          child: _MenuRow(
            icon: Icons.refresh,
            label: context.l10n.paywallRestore,
          ),
        ),
        PopupMenuItem(
          value: 'terms',
          child: _MenuRow(
            icon: Icons.description_outlined,
            label: context.l10n.paywallTerms,
          ),
        ),
        PopupMenuItem(
          value: 'privacy',
          child: _MenuRow(
            icon: Icons.lock_outline,
            label: context.l10n.paywallPrivacy,
          ),
        ),
        PopupMenuItem(
          value: 'code',
          child: _MenuRow(
            icon: Icons.card_giftcard,
            label: context.l10n.paywallHaveCode,
          ),
        ),
        if (kDebugMode)
          PopupMenuItem(
            value: 'restart',
            child: _MenuRow(
              icon: Icons.restart_alt,
              label: context.l10n.restartOnboarding,
            ),
          ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.onSurface),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan picker — two side-by-side cards with a floating "3 days free" badge
// over the yearly card's top edge.
// ---------------------------------------------------------------------------
class _PlanPicker extends StatelessWidget {
  final int selected;
  final String weeklyPrice;
  final String yearlyPrice;
  final String weeklyLabel;
  final String yearlyLabel;
  final String save85Label;
  final String trialBadgeLabel;
  final Color brandBlue;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final ValueChanged<int> onSelect;

  const _PlanPicker({
    required this.selected,
    required this.weeklyPrice,
    required this.yearlyPrice,
    required this.weeklyLabel,
    required this.yearlyLabel,
    required this.save85Label,
    required this.trialBadgeLabel,
    required this.brandBlue,
    required this.cardBg,
    required this.ink,
    required this.muted,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Negative top inset reserves space for the absolutely-positioned
      // "3 days free" badge that sticks out above the yearly card.
      padding: const EdgeInsets.only(top: 13),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: _PlanCard(
                  title: weeklyLabel,
                  priceLine: weeklyPrice,
                  saveLine: null,
                  selected: selected == 0,
                  brandBlue: brandBlue,
                  cardBg: cardBg,
                  ink: ink,
                  muted: muted,
                  onTap: () => onSelect(0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PlanCard(
                  title: yearlyLabel,
                  priceLine: yearlyPrice,
                  saveLine: save85Label,
                  selected: selected == 1,
                  brandBlue: brandBlue,
                  cardBg: cardBg,
                  ink: ink,
                  muted: muted,
                  onTap: () => onSelect(1),
                ),
              ),
              ],
            ),
          ),
          // Floating "3 days free" badge centered over the yearly card.
          // The yearly card occupies the right half of the row; we span the
          // full row width with left+right=0 and use Alignment(0.5, 0) to
          // pin the child to the centre of that right half.
          Positioned(
            top: -13,
            left: 0,
            right: 0,
            child: Align(
              alignment: const Alignment(0.5, 0),
              child: _TrialBadge(
                label: trialBadgeLabel,
                color: brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String priceLine;
  final String? saveLine;
  final bool selected;
  final Color brandBlue;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.priceLine,
    required this.saveLine,
    required this.selected,
    required this.brandBlue,
    required this.cardBg,
    required this.ink,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        // No fixed height — intrinsic content drives the height so two- vs
        // three-line cards stay aligned via the parent's stretch.
        // 2pt border on the selected variant eats inward, so subtract it
        // from the padding to keep the visual inset a consistent 16pt.
        padding: EdgeInsets.all(selected ? 14 : 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white : cardBg,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(color: brandBlue, width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 20 / 16,
                      color: ink,
                    ),
                  ),
                  if (saveLine != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      saveLine!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: brandBlue,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    priceLine,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      height: 20 / 16,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PlanCheckbox(selected: selected, brandBlue: brandBlue),
          ],
        ),
      ),
    );
  }
}

class _PlanCheckbox extends StatelessWidget {
  final bool selected;
  final Color brandBlue;

  const _PlanCheckbox({required this.selected, required this.brandBlue});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? brandBlue : Colors.transparent,
        shape: BoxShape.circle,
        border: selected
            ? null
            : Border.all(color: const Color(0xFFCBD0DC), width: 2),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _TrialBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TrialBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 18 / 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trial countdown card — 3 rows: Day 1, Day 3, Day 4 with descriptions.
// ---------------------------------------------------------------------------
class _TrialCountdown extends StatelessWidget {
  final Color cardBg;
  final Color ink;
  final Color faint;
  final String day1Label;
  final String day3Label;
  final String day4Label;
  final String trialStarts;
  final String remindYou;
  final String planBegins;

  /// Suffix appended to the "Plan begins" row, e.g. " · $39.99/year".
  /// Empty string when the yearly product hasn't loaded yet.
  final String planPriceSuffix;

  const _TrialCountdown({
    required this.cardBg,
    required this.ink,
    required this.faint,
    required this.day1Label,
    required this.day3Label,
    required this.day4Label,
    required this.trialStarts,
    required this.remindYou,
    required this.planBegins,
    required this.planPriceSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _TrialRow(dayLabel: day1Label, description: trialStarts, ink: ink),
          const SizedBox(height: 12),
          _TrialRow(dayLabel: day3Label, description: remindYou, ink: ink),
          const SizedBox(height: 12),
          _TrialRow(
            dayLabel: day4Label,
            description: planBegins,
            descriptionSuffix: planPriceSuffix,
            suffixColor: faint,
            ink: ink,
          ),
        ],
      ),
    );
  }
}

class _TrialRow extends StatelessWidget {
  final String dayLabel;
  final String description;
  final String descriptionSuffix;
  final Color? suffixColor;
  final Color ink;

  const _TrialRow({
    required this.dayLabel,
    required this.description,
    required this.ink,
    this.descriptionSuffix = '',
    this.suffixColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            dayLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 18 / 14,
              color: ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 20 / 16,
                    color: ink,
                  ),
                ),
                if (descriptionSuffix.isNotEmpty)
                  TextSpan(
                    text: descriptionSuffix,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 20 / 16,
                      color: suffixColor ?? ink,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Features card — 4 short bullet lines on the neutral card bg.
// ---------------------------------------------------------------------------
class _FeaturesCard extends StatelessWidget {
  final Color cardBg;
  final Color ink;
  final List<({String emoji, String text})> features;

  const _FeaturesCard({
    required this.cardBg,
    required this.ink,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < features.length; i++) ...[
            Row(
              children: [
                NotoEmoji(name: features[i].emoji, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    features[i].text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 22 / 15,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
            if (i != features.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar — pinned to the bottom edge, holds the trial-no-payment row,
// the primary CTA and the renewal disclaimer.
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final bool showNoPayment;
  final String ctaLabel;
  final bool ctaEnabled;
  final bool isBusy;
  final String noPaymentLabel;
  final String disclaimer;
  final VoidCallback? onCta;
  final Color ink;
  final Color muted;

  const _BottomBar({
    required this.showNoPayment,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.isBusy,
    required this.noPaymentLabel,
    required this.disclaimer,
    required this.onCta,
    required this.ink,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightOnBack,
        border: Border(top: BorderSide(color: AppColors.lineLight100)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showNoPayment) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 22, color: ink),
                      const SizedBox(width: 6),
                      Text(
                        noPaymentLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 22 / 16,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _PrimaryButton(
                  label: ctaLabel,
                  isLoading: isBusy,
                  onPressed: ctaEnabled ? onCta : null,
                ),
                const SizedBox(height: 12),
                Text(
                  disclaimer,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 18 / 14,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.onboardingCtaBg
              : AppColors.onboardingCtaBg.withAlpha(120),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 22 / 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promo code input sheet (unchanged from previous version)
// ---------------------------------------------------------------------------
class _PromoCodeSheet extends StatefulWidget {
  const _PromoCodeSheet();

  @override
  State<_PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<_PromoCodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isNotEmpty) {
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.paywallHaveCode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: TextStyle(
                  fontSize: 24,
                  color: cs.outline.withAlpha(100),
                  letterSpacing: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              maxLength: 4,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submit,
                child: Text(
                  context.l10n.promoCodeApply,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
