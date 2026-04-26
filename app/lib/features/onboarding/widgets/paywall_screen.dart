import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Make sure products are fetched by the time the user taps the CTA.
    sub.ensureProductsLoaded();
  }

  void _onAuthChanged() {
    if (AuthService().isPremium && mounted) {
      context.go('/diary');
    }
  }

  /// Fires on every [SubscriptionService] state change — triggers a rebuild
  /// so the CTA can reflect loading / disabled / ready states.
  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  /// Handles one-shot events delivered via the broadcast event stream.
  /// Every event corresponds to exactly one UI reaction (dialog or snackbar).
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
        // Silent — user explicitly dismissed the Apple sheet.
        break;
      case PurchaseSuccessEvent():
        // Navigation happens via AuthService listener when premium flips on.
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

  String get _trialEndDate {
    final end = DateTime.now().add(const Duration(days: 3));
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(end);
  }

  ProductDetails? get _weeklyProduct =>
      SubscriptionService().productById(SubscriptionService.weeklyId);

  ProductDetails? get _yearlyProduct =>
      SubscriptionService().productById(SubscriptionService.yearlyId);

  bool _productsLoadFailed(SubscriptionService sub) =>
      sub.state == SubState.noProducts || sub.state == SubState.unavailable;

  bool _productsAreLoading(SubscriptionService sub) =>
      sub.state == SubState.initializing ||
      (sub.state == SubState.idle && sub.products.isEmpty);

  String _weeklyPriceLabel(SubscriptionService sub) {
    final p = _weeklyProduct;
    if (p == null && _productsLoadFailed(sub)) {
      return '—';
    }
    if (p == null) return context.l10n.paywallLoadingPrice;
    return '${p.price} / ${context.l10n.paywallPerWeek}';
  }

  String _yearlyPriceLabel(SubscriptionService sub) {
    final p = _yearlyProduct;
    if (p == null && _productsLoadFailed(sub)) {
      return '—';
    }
    if (p == null) return context.l10n.paywallLoadingPrice;
    return '${p.price} / ${context.l10n.paywallPerYear}';
  }

  String _trialDisclaimer() {
    final p = _yearlyProduct;
    if (p == null) return context.l10n.paywallTrialDisclaimer;
    return context.l10n.paywallTrialDisclaimerFmt(p.price);
  }

  Future<void> _subscribe() async {
    final sub = SubscriptionService();
    // The CTA is only enabled when products are ready; this guard is a
    // belt-and-braces safety net rather than an expected code path.
    if (sub.products.isEmpty) return;

    final productId = _selectedPlan == 0
        ? SubscriptionService.weeklyId
        : SubscriptionService.yearlyId;

    final product = sub.productById(productId) ?? sub.products.first;
    await sub.buy(product);
    // Success / failure / cancel are delivered via the events stream.
  }

  /// Triggers a user-initiated restore. The service emits a
  /// [RestoreCompletedEvent] or [RestoreFailedEvent] which is handled in
  /// [_onSubEvent] — this function just fires and forgets.
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
    final cs = Theme.of(context).colorScheme;
    final isHard = _isHardPaywall;
    final canGoBack = !isHard && Navigator.of(context).canPop();
    final sub = SubscriptionService();

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    children: [
                      // --- Top bar ---
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            if (canGoBack)
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: cs.onSurface,
                                  size: 24,
                                ),
                              )
                            else
                              const SizedBox(width: 48),
                            const Spacer(),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: cs.onSurfaceVariant,
                                size: 24,
                              ),
                              onSelected: (value) {
                                switch (value) {
                                  case 'restore':
                                    _restore();
                                  case 'terms':
                                    launchUrl(
                                      Uri.parse(_termsUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  case 'privacy':
                                    launchUrl(
                                      Uri.parse(_privacyUrl),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  case 'code':
                                    _redeemCode();
                                  case 'diagnostics':
                                    _showDiagnostics();
                                  case 'restart':
                                    AuthService().resetOnboarding();
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'restore',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        size: 20,
                                        color: cs.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(context.l10n.paywallRestore),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'terms',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 20,
                                        color: cs.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(context.l10n.paywallTerms),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'privacy',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 20,
                                        color: cs.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(context.l10n.paywallPrivacy),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'code',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        size: 20,
                                        color: cs.onSurface,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(context.l10n.paywallHaveCode),
                                    ],
                                  ),
                                ),
                                if (kDebugMode) ...[
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'diagnostics',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.bug_report_outlined,
                                          size: 20,
                                          color: cs.onSurface,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('IAP diagnostics'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'restart',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.restart_alt,
                                          size: 20,
                                          color: cs.onSurface,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(context.l10n.restartOnboarding),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // --- Scrollable content ---
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),

                              // --- Title ---
                              Text(
                                isHard
                                    ? context.l10n.paywallHardTitle
                                    : context.l10n.paywallTitle,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: cs.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              if (!isHard) ...[
                                _TimelineItem(
                                  svgAsset: 'assets/icons/lock_unlocked.svg',
                                  iconBg: cs.primary,
                                  title: context.l10n.paywallTimelineTodayTitle,
                                  description:
                                      context.l10n.paywallTimelineTodayDesc,
                                  isFirst: true,
                                  isLast: false,
                                ),
                                _TimelineItem(
                                  svgAsset: 'assets/icons/bell.svg',
                                  iconBg: cs.primary,
                                  title:
                                      context.l10n.paywallTimelineReminderTitle,
                                  description:
                                      context.l10n.paywallTimelineReminderDesc,
                                  isFirst: false,
                                  isLast: false,
                                ),
                                _TimelineItem(
                                  svgAsset: 'assets/icons/crown.svg',
                                  iconBg: cs.inverseSurface,
                                  iconColor: cs.surface,
                                  title: context.l10n.paywallTimelinePayTitle,
                                  description: context.l10n
                                      .paywallTimelinePayDesc(_trialEndDate),
                                  isFirst: false,
                                  isLast: true,
                                ),
                                const SizedBox(height: 28),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: _PlanCard(
                                      title: context.l10n.paywallMonthly,
                                      price: _weeklyPriceLabel(sub),
                                      badge: null,
                                      isSelected: _selectedPlan == 0,
                                      isLoading:
                                          _weeklyProduct == null &&
                                          _productsAreLoading(sub),
                                      onTap: () =>
                                          setState(() => _selectedPlan = 0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PlanCard(
                                      title: context.l10n.paywallYearly,
                                      price: _yearlyPriceLabel(sub),
                                      badge: isHard
                                          ? null
                                          : context.l10n.paywallTrialBadge,
                                      isSelected: _selectedPlan == 1,
                                      isLoading:
                                          _yearlyProduct == null &&
                                          _productsAreLoading(sub),
                                      onTap: () =>
                                          setState(() => _selectedPlan = 1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              if (!isHard)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 18,
                                      color: cs.onSurface,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.l10n.paywallNoPaymentNow,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      _buildBottomCTA(context, sub),
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

  Widget _buildBottomCTA(BuildContext context, SubscriptionService sub) {
    final cs = Theme.of(context).colorScheme;
    final isHard = _isHardPaywall;

    // The main CTA is tappable only when products are loaded and no purchase
    // is currently in flight.
    final bool isPurchasing = sub.state == SubState.purchasing;
    final bool isLoading = _productsAreLoading(sub);
    final bool canSubscribe =
        sub.state == SubState.ready && sub.products.isNotEmpty;
    final bool canRetry = _productsLoadFailed(sub);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isPurchasing
                  ? null
                  : canSubscribe
                  ? _subscribe
                  : canRetry
                  ? SubscriptionService().retryProductsLoading
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.onSurface,
                foregroundColor: cs.surface,
                disabledBackgroundColor: cs.onSurface.withAlpha(90),
                disabledForegroundColor: cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: (isPurchasing || isLoading)
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(cs.surface),
                      ),
                    )
                  : Text(
                      canRetry
                          ? context.l10n.paywallTryAgain
                          : isHard
                          ? context.l10n.paywallSubscribeNow
                          : context.l10n.paywallStartTrial,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isHard ? context.l10n.paywallHardDisclaimer : _trialDisclaimer(),
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(_termsUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  context.l10n.paywallTerms,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '·',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(_privacyUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  context.l10n.paywallPrivacy,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (!isHard) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _skip,
              child: Text(
                context.l10n.paywallSkip,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showDiagnostics() async {
    final sub = SubscriptionService();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('IAP diagnostics'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('state: ${sub.state}'),
                  if (sub.lastFailureDetails != null)
                    Text('lastFailure: ${sub.lastFailureDetails}'),
                  const SizedBox(height: 8),
                  Text(
                    'products (${sub.products.length}): ${sub.products.map((p) => '${p.id}=${p.price}').join(', ')}',
                  ),
                  const Divider(),
                  const Text(
                    'logs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...sub.logs.reversed.map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                SubscriptionService().ensureProductsLoaded();
              },
              child: const Text('Re-query products'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Vertical timeline item
// ---------------------------------------------------------------------------
class _TimelineItem extends StatelessWidget {
  final String svgAsset;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String description;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.svgAsset,
    required this.iconBg,
    this.iconColor,
    required this.title,
    required this.description,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: circle + line
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        svgAsset,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          iconColor ?? Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cs.outline.withAlpha(50),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card (monthly / yearly)
// ---------------------------------------------------------------------------
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.badge,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? cs.onSurface : cs.outline.withAlpha(80),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? cs.onSurface : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? cs.onSurface
                              : cs.outline.withAlpha(120),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 14, color: cs.surface)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  SizedBox(
                    height: 22,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cs.surface,
                    letterSpacing: 0.5,
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
// Promo code input sheet
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
