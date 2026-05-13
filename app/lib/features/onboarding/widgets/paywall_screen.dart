import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      AnalyticsService.instance.logEvent(
        'paywall_viewed',
        parameters: {'plan': _planIdForIndex(_selectedPlan)},
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The free-trial path has been removed — paywall is always the
    // single gate between non-premium users and the app. No back, no
    // skip; the only ways out are buy, redeem a promo, or quit.
    const canGoBack = false;
    final sub = SubscriptionService();

    final bgColor = isDark ? AppColors.darkBack3 : AppColors.lightBack3;
    final textPrimary = isDark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;
    final textSecondary = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Stack(
                    children: [
                  Column(
                    children: [
                      _TopBar(
                        canGoBack: canGoBack,
                        canSkip: false,
                        isDark: isDark,
                        onBack: () => Navigator.of(context).pop(),
                        onRestore: _restore,
                        onTerms: () {
                          unawaited(
                            AnalyticsService.instance.logEvent(
                              'paywall_terms_opened',
                            ),
                          );
                          launchUrl(
                            Uri.parse(_termsUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        onPrivacy: () {
                          unawaited(
                            AnalyticsService.instance.logEvent(
                              'paywall_privacy_opened',
                            ),
                          );
                          launchUrl(
                            Uri.parse(_privacyUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        onCode: _redeemCode,
                        onSkip: () {},
                        onRestart: () => AuthService().resetOnboarding(),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 220),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _Hero(isDark: isDark, bgColor: bgColor),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _BrandTitle(textPrimary: textPrimary),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.paywallSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 20 / 16,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _PlanRow(
                                title: context.l10n.paywallYearly,
                                price: _yearlyPriceLabel(sub),
                                discountBadge:
                                    context.l10n.paywallYearlyDiscount,
                                // Free-trial pill on the yearly card —
                                // the intro is configured on Apple's
                                // side, but surfacing the duration here
                                // converts better than letting users
                                // discover it only on the App Store
                                // purchase sheet.
                                trialBadge: context.l10n.paywallTrialBadge,
                                isSelected: _selectedPlan == 1,
                                isLoading:
                                    _yearlyProduct == null &&
                                    _productsAreLoading(sub),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                onTap: () => _selectPlan(1),
                              ),
                              const SizedBox(height: 6),
                              _PlanRow(
                                title: context.l10n.paywallMonthly,
                                price: _weeklyPriceLabel(sub),
                                discountBadge: null,
                                trialBadge: null,
                                isSelected: _selectedPlan == 0,
                                isLoading:
                                    _weeklyProduct == null &&
                                    _productsAreLoading(sub),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                onTap: () => _selectPlan(0),
                              ),
                              const SizedBox(height: 16),
                              _FeatureCard(
                                imageAsset: 'assets/paywall/feature_ai.png',
                                title: context.l10n.paywallFeatureAiTitle,
                                description: context.l10n.paywallFeatureAiDesc,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              const SizedBox(height: 8),
                              _FeatureCard(
                                imageAsset: 'assets/paywall/feature_diary.png',
                                title: context.l10n.paywallFeatureDiaryTitle,
                                description:
                                    context.l10n.paywallFeatureDiaryDesc,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              const SizedBox(height: 8),
                              _FeatureCard(
                                imageAsset:
                                    'assets/paywall/feature_analytics.png',
                                title: context
                                    .l10n
                                    .paywallFeatureAnalyticsTitle,
                                description:
                                    context.l10n.paywallFeatureAnalyticsDesc,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              const SizedBox(height: 8),
                              _FeatureCard(
                                imageAsset:
                                    'assets/paywall/feature_barcode.png',
                                title:
                                    context.l10n.paywallFeatureBarcodeTitle,
                                description:
                                    context.l10n.paywallFeatureBarcodeDesc,
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom CTA overlays the scrollable content so the page
                  // continues underneath. A 24-pt gradient strip on top of
                  // the panel fades that content into the panel background,
                  // avoiding a hard divider line.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IgnorePointer(
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  bgColor.withAlpha(0),
                                  bgColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                        _BottomCTA(
                          bgColor: bgColor,
                          isDark: isDark,
                          sub: sub,
                          canSubscribe:
                              sub.state == SubState.ready &&
                              _selectedProduct != null,
                          canRetry: _productsLoadFailed(sub),
                          isPurchasing: sub.state == SubState.purchasing,
                          isLoading: _productsAreLoading(sub),
                          ctaLabel: _ctaLabel(),
                          disclaimer: context.l10n.paywallHardDisclaimer,
                          // Yearly ships with a free trial — surface the
                          // same reassurance line that the onboarding
                          // result / trial-reminder steps show above
                          // their CTA. _BottomCTA already mirrors that
                          // layout (check 22, label 16/w500, 20-pt gap
                          // to button), so flipping the flag is enough
                          // to match those screens verbatim.
                          showNoPayment: true,
                          noPaymentVisible: _selectedPlanHasTrial,
                          textPrimary: textPrimary,
                          onSubscribe: _subscribe,
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
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
// Top bar with back arrow and kebab menu
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final bool canGoBack;
  final bool canSkip;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback onCode;
  final VoidCallback onSkip;
  final VoidCallback onRestart;

  const _TopBar({
    required this.canGoBack,
    required this.canSkip,
    required this.isDark,
    required this.onBack,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
    required this.onCode,
    required this.onSkip,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Row(
        children: [
          if (canGoBack)
            _SquareIconButton(
              bgColor: surfaceColor,
              isDark: isDark,
              onTap: onBack,
              child: Icon(Icons.arrow_back, color: iconColor, size: 20),
            )
          else
            const SizedBox(width: 32, height: 32),
          const Spacer(),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 40),
            child: _SquareIconButton(
              bgColor: surfaceColor,
              isDark: isDark,
              onTap: null,
              child: Icon(Icons.more_vert, color: iconColor, size: 20),
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
                case 'skip':
                  onSkip();
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
              if (canSkip)
                PopupMenuItem(
                  value: 'skip',
                  child: _MenuRow(
                    icon: Icons.skip_next_outlined,
                    label: context.l10n.paywallSkip,
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
          ),
        ],
      ),
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

class _SquareIconButton extends StatelessWidget {
  final Color bgColor;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget child;

  const _SquareIconButton({
    required this.bgColor,
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x081B364A),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top illustration — separate light/dark assets per design
// ---------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  final bool isDark;
  final Color bgColor;
  const _Hero({required this.isDark, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    final asset = isDark
        ? 'assets/paywall/dark/hero.png'
        : 'assets/paywall/light/hero.png';

    // Both light and dark hero PNGs are ~1570×808 (≈1.94:1). AspectRatio
    // makes the widget stretch edge-to-edge while keeping proportions, so
    // the illustration goes from screen edge to screen edge regardless of
    // device width.
    return AspectRatio(
      aspectRatio: 1572 / 808,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          // Subtle bottom fade so the illustration blends into the page bg.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 24,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgColor.withAlpha(0), bgColor],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "BodyMeal" + Pro badge title row
// ---------------------------------------------------------------------------
class _BrandTitle extends StatelessWidget {
  final Color textPrimary;
  const _BrandTitle({required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'BodyMeal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        SvgPicture.asset(
          'assets/paywall/pro.svg',
          height: 24,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Plan row (yearly/weekly) with checkbox, optional discount pill and trial chip
// ---------------------------------------------------------------------------
class _PlanRow extends StatelessWidget {
  final String title;
  final String price;
  final String? discountBadge;
  final String? trialBadge;
  final bool isSelected;
  final bool isLoading;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _PlanRow({
    required this.title,
    required this.price,
    required this.discountBadge,
    required this.trialBadge,
    required this.isSelected,
    required this.isLoading,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;
    final cs = Theme.of(context).colorScheme;
    final inverse = cs.inverseSurface;
    final inverseText = cs.onInverseSurface;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                top: BorderSide(color: AppColors.lineDT50, width: 2),
              ),
              boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _RadioIcon(isSelected: isSelected),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                    color: textPrimary,
                  ),
                ),
                if (discountBadge != null) ...[
                  const SizedBox(width: 4),
                  _DiscountPill(text: discountBadge!),
                ],
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(textSecondary),
                    ),
                  )
                else
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trialBadge != null)
            Positioned(
              top: -10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: inverse,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  trialBadge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 14 / 12,
                    color: inverseText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  final bool isSelected;
  const _RadioIcon({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: SvgPicture.asset(
        isSelected
            ? 'assets/paywall/radio_on.svg'
            : 'assets/paywall/radio_off.svg',
      ),
    );
  }
}

class _DiscountPill extends StatelessWidget {
  final String text;
  const _DiscountPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 14 / 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature card (image + title + description)
// ---------------------------------------------------------------------------
class _FeatureCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String description;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _FeatureCard({
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkOnBack4 : AppColors.lightOnBack4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: AppColors.lineDT50, width: 2),
        ),
        boxShadow: AppTheme.cardEdgeShadows(isDark: isDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Image.asset(imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 20 / 16,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 18 / 14,
                    color: textSecondary,
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

// ---------------------------------------------------------------------------
// Bottom CTA block: primary button + disclaimer + optional skip
// ---------------------------------------------------------------------------
class _BottomCTA extends StatelessWidget {
  final Color bgColor;
  final bool isDark;
  final SubscriptionService sub;
  final bool canSubscribe;
  final bool canRetry;
  final bool isPurchasing;
  final bool isLoading;
  final String ctaLabel;
  final String disclaimer;
  final bool showNoPayment;
  final bool noPaymentVisible;
  final Color textPrimary;
  final VoidCallback onSubscribe;

  const _BottomCTA({
    required this.bgColor,
    required this.isDark,
    required this.sub,
    required this.canSubscribe,
    required this.canRetry,
    required this.isPurchasing,
    required this.isLoading,
    required this.ctaLabel,
    required this.disclaimer,
    required this.showNoPayment,
    required this.noPaymentVisible,
    required this.textPrimary,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final disclaimerColor = isDark
        ? AppColors.darkOnSurfaceVariant
        : AppColors.lightOnSurfaceVariant;

    final VoidCallback? handler = isPurchasing
        ? null
        : canSubscribe
        ? onSubscribe
        : canRetry
        ? SubscriptionService().retryProductsLoading
        : null;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mirrors the trial-reminder step layout: check 22, label
              // 16/w500, 20-pt gap to the CTA. Conditionally rendered so the
              // panel shrinks slightly when a plan without a free trial is
              // selected — AnimatedSize handles the height transition.
              if (showNoPayment && noPaymentVisible) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/paywall/check.svg',
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.paywallNoPaymentNow,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 22 / 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              _PrimaryButton(
                label: ctaLabel,
                isLoading: isPurchasing || isLoading,
                onPressed: handler,
              ),
              const SizedBox(height: 12),
              Text(
                disclaimer,
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  color: disclaimerColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
              ? AppColors.primary
              : AppColors.primary.withAlpha(120),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 22 / 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Promo code input sheet (unchanged)
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
