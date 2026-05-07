import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:meal_tracker/app/theme.dart';
import 'package:meal_tracker/core/services/analytics_service.dart';
import 'package:meal_tracker/core/services/auth_service.dart';
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
        parameters: {'is_hard_paywall': _isHardPaywall ? 1 : 0},
      ),
    );

    sub.ensureProductsLoaded();
  }

  void _onAuthChanged() {
    if (AuthService().isPremium && mounted) {
      context.go('/diary');
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSubEvent(SubEvent event) {
    if (!mounted) return;
    final l = context.l10n;

    switch (event) {
      case StoreUnavailableEvent():
        _showErrorDialog(l.paywallErrorStoreUnavailable);
      case ProductsEmptyEvent():
        _showErrorDialog(l.paywallErrorProductsEmpty);
      case ProductsLoadFailedEvent(details: final d):
        _showErrorDialog(l.paywallErrorQueryFailed, debugDetails: d);
      case PurchaseFailedEvent(details: final d):
        _showErrorDialog(l.paywallErrorPurchaseFailed, debugDetails: d);
      case PaymentPendingEvent():
        _showErrorDialog(l.paywallErrorPaymentPending, showRetry: false);
      case PurchaseCanceledEvent():
        break;
      case PurchaseSuccessEvent():
        break;
      case RestoreCompletedEvent(foundActive: final found):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              found ? l.paywallRestoreSuccess : l.paywallRestoreNotFound,
            ),
          ),
        );
      case RestoreFailedEvent(details: final d):
        _showErrorDialog(l.paywallErrorRestoreFailed, debugDetails: d);
    }
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    SubscriptionService().removeListener(_onStateChanged);
    _eventsSub?.cancel();
    _enterController.dispose();
    super.dispose();
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

  String _trialDisclaimer() {
    final p = _yearlyProduct;
    if (p == null) return context.l10n.paywallTrialDisclaimer;
    return context.l10n.paywallTrialDisclaimerFmt(p.price);
  }

  String _selectedPlanDisclaimer() {
    if (_selectedPlanHasTrial) return _trialDisclaimer();
    return context.l10n.paywallWeeklyDisclaimer;
  }

  Future<void> _subscribe() async {
    final sub = SubscriptionService();
    if (sub.products.isEmpty) return;

    final productId = _selectedPlan == 0
        ? SubscriptionService.weeklyId
        : SubscriptionService.yearlyId;

    final product = sub.productById(productId);
    if (product == null) {
      _showErrorDialog(context.l10n.paywallErrorSelectedProductUnavailable);
      return;
    }

    await sub.buy(product);
  }

  void _restore() {
    SubscriptionService().restore();
  }

  bool get _isHardPaywall => AuthService().freeTrialExhausted;

  void _skip() {
    context.go('/diary');
  }

  Future<void> _redeemCode() async {
    if (!mounted) return;
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PromoCodeSheet(),
    );
    if (code == null || !mounted) return;

    const validCodes = {'8259', '2170'};
    if (validCodes.contains(code.trim())) {
      await AuthService().setPremium(isPremium: true, planName: 'promo_$code');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.promoCodeInvalid)));
    }
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
    final isHard = _isHardPaywall;
    final canGoBack = !isHard && Navigator.of(context).canPop();
    final sub = SubscriptionService();

    final bgColor = isDark ? AppColors.darkBack3 : AppColors.lightBack3;
    final textPrimary = isDark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;
    final textSecondary = isDark
        ? AppColors.darkSecondaryDark
        : AppColors.lightSecondaryDark;
    final textPrimaryLight = isDark
        ? AppColors.darkPrimaryLight
        : AppColors.lightPrimaryLight;

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
                  child: Column(
                    children: [
                      _TopBar(
                        canGoBack: canGoBack,
                        canSkip: !isHard,
                        isDark: isDark,
                        onBack: () => Navigator.of(context).pop(),
                        onRestore: _restore,
                        onTerms: () => launchUrl(
                          Uri.parse(_termsUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        onPrivacy: () => launchUrl(
                          Uri.parse(_privacyUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        onCode: _redeemCode,
                        onSkip: _skip,
                        onRestart: () => AuthService().resetOnboarding(),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _Hero(isDark: isDark, bgColor: bgColor),
                              const SizedBox(height: 8),
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
                                trialBadge: !isHard
                                    ? context.l10n.paywallTrialBadge
                                    : null,
                                isSelected: _selectedPlan == 1,
                                isLoading:
                                    _yearlyProduct == null &&
                                    _productsAreLoading(sub),
                                isDark: isDark,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                onTap: () =>
                                    setState(() => _selectedPlan = 1),
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
                                onTap: () =>
                                    setState(() => _selectedPlan = 0),
                              ),
                              if (!isHard) ...[
                                const SizedBox(height: 14),
                                Visibility(
                                  visible: _selectedPlanHasTrial,
                                  maintainState: true,
                                  maintainAnimation: true,
                                  maintainSize: true,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/paywall/check.svg',
                                        width: 18,
                                        height: 18,
                                        colorFilter: ColorFilter.mode(
                                          textPrimaryLight,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        context.l10n.paywallNoPaymentNow,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          height: 18 / 14,
                                          color: textPrimaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                        disclaimer: isHard
                            ? context.l10n.paywallHardDisclaimer
                            : _selectedPlanDisclaimer(),
                        onSubscribe: _subscribe,
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
    if (_isHardPaywall) return l.paywallSubscribeNow;
    return _selectedPlanHasTrial ? l.paywallStartTrial : l.paywallSubscribeNow;
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

    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.contain),
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
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? AppColors.darkDividerLight
        : AppColors.lightDividerLight;
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
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: dividerColor, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrimaryButton(
              label: ctaLabel,
              isLoading: isPurchasing || isLoading,
              onPressed: handler,
            ),
            const SizedBox(height: 10),
            Text(
              disclaimer,
              style: TextStyle(fontSize: 11, color: disclaimerColor),
              textAlign: TextAlign.center,
            ),
          ],
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
          border: const Border(
            top: BorderSide(color: Color(0xFF74A6FF), width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF153773),
              offset: Offset(0, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
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
