import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:meal_tracker/core/services/auth_service.dart';

// =============================================================================
// State (reactive, for UI like button enabled/disabled, spinner)
// =============================================================================

/// Lifecycle state of the subscription layer.
///
/// The paywall CTA is only tappable when [ready]; during [initializing],
/// [purchasing], [restoring] it shows a spinner; [unavailable] / [noProducts]
/// mean the user can't purchase right now.
enum SubState {
  idle,
  initializing,
  ready,
  unavailable,
  noProducts,
  purchasing,
  restoring,
}

// =============================================================================
// Events (one-shot, consumed by UI via Stream for dialogs / snackbars)
// =============================================================================

/// Base class for transient notifications delivered via
/// [SubscriptionService.events]. Each event is emitted once per occurrence.
sealed class SubEvent {
  const SubEvent();
}

/// StoreKit is not available (no App Store account, parental controls, etc).
class StoreUnavailableEvent extends SubEvent {
  const StoreUnavailableEvent();
}

/// Every retry of [queryProductDetails] either threw or returned an error.
/// The exact cause is in [details] (network, sandbox misconfig, etc.).
class ProductsLoadFailedEvent extends SubEvent {
  final String? details;
  const ProductsLoadFailedEvent(this.details);
}

/// StoreKit responded successfully but returned no matching products — almost
/// always an App Store Connect configuration issue (products not approved,
/// not attached to the build, or Paid Apps Agreement missing).
class ProductsEmptyEvent extends SubEvent {
  const ProductsEmptyEvent();
}

class PurchaseSuccessEvent extends SubEvent {
  const PurchaseSuccessEvent();
}

class PurchaseFailedEvent extends SubEvent {
  final String? details;
  const PurchaseFailedEvent(this.details);
}

class PurchaseCanceledEvent extends SubEvent {
  const PurchaseCanceledEvent();
}

/// Apple put the payment into deferred/pending state (fraud review, credit
/// card authorization, parental approval). Resolution can take minutes or
/// days — the UI must release the spinner and explain.
class PaymentPendingEvent extends SubEvent {
  const PaymentPendingEvent();
}

/// Emitted once after a user-initiated [SubscriptionService.restore] has had
/// a reasonable window to deliver any `.restored` events.
class RestoreCompletedEvent extends SubEvent {
  final bool foundActive;
  const RestoreCompletedEvent({required this.foundActive});
}

class RestoreFailedEvent extends SubEvent {
  final String? details;
  const RestoreFailedEvent(this.details);
}

// =============================================================================
// Service
// =============================================================================

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String weeklyId = 'weekly_premium';
  static const String yearlyId = 'yearly_premium';
  static const Set<String> _productIds = {weeklyId, yearlyId};

  /// Window after [restore] completes before deciding "nothing to restore".
  /// StoreKit delivers `.restored` events asynchronously after
  /// `restorePurchases()` returns, so we need to wait briefly.
  static const Duration _restoreSettleWindow = Duration(milliseconds: 1500);

  // ---------------------------------------------------------------------------
  // State (ChangeNotifier)
  // ---------------------------------------------------------------------------
  SubState _state = SubState.idle;
  SubState get state => _state;

  List<ProductDetails> products = [];
  bool get isReady => _state == SubState.ready;

  // ---------------------------------------------------------------------------
  // Events (broadcast stream)
  // ---------------------------------------------------------------------------
  final StreamController<SubEvent> _eventsController =
      StreamController<SubEvent>.broadcast();
  Stream<SubEvent> get events => _eventsController.stream;

  void _emit(SubEvent event) {
    _log('event: ${event.runtimeType}');
    _eventsController.add(event);
  }

  // ---------------------------------------------------------------------------
  // Restore window tracking (see [_restoreSettleWindow])
  // ---------------------------------------------------------------------------
  bool _restoreInProgress = false;
  int _restoreEventsSeen = 0;

  // ---------------------------------------------------------------------------
  // Diagnostics log (used by debug menu)
  // ---------------------------------------------------------------------------
  static const int _logCapacity = 80;
  final Queue<String> _logs = Queue<String>();
  List<String> get logs => List.unmodifiable(_logs);

  /// Only populated when an operation fails; intended for the debug
  /// diagnostics panel, not for surfacing to end users.
  String? _lastFailureDetails;
  String? get lastFailureDetails => _lastFailureDetails;

  void _log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    final line = '[$ts] $msg';
    if (_logs.length >= _logCapacity) _logs.removeFirst();
    _logs.addLast(line);
    debugPrint('SubscriptionService $line');
  }

  // ---------------------------------------------------------------------------
  // Init — idempotent
  // ---------------------------------------------------------------------------
  bool _initStarted = false;
  Completer<void>? _initCompleter;

  Future<void> init() {
    if (_initStarted && _initCompleter != null) return _initCompleter!.future;
    _initStarted = true;
    _initCompleter = Completer<void>();
    _runInit().whenComplete(() {
      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
    });
    return _initCompleter!.future;
  }

  Future<void> _runInit() async {
    _setState(SubState.initializing);

    // 1. Subscribe to the purchase stream FIRST, before any other async work.
    // StoreKit begins delivering pending transactions as soon as
    // [InAppPurchase.instance] is accessed; subscribing late can drop them.
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        _log('purchaseStream error: $error');
        _lastFailureDetails = '$error';
        _emit(PurchaseFailedEvent('$error'));
        if (_state == SubState.purchasing || _state == SubState.restoring) {
          _setState(SubState.ready);
        }
      },
    );

    // 2. Check store availability.
    bool available = false;
    try {
      available = await _iap.isAvailable();
    } catch (e) {
      _log('isAvailable threw: $e');
      _lastFailureDetails = '$e';
    }

    if (!available) {
      _log('Store not available');
      _emit(const StoreUnavailableEvent());
      _setState(SubState.unavailable);
      return;
    }

    // 3. Load products (with retry).
    await _loadProducts();

    // 4. Kick off a silent restore so users with an existing subscription get
    // Pro back without any action. No event is emitted for silent restore —
    // the purchase stream handler will activate premium if applicable.
    try {
      _log('restorePurchases (silent)');
      await _iap.restorePurchases();
    } catch (e) {
      _log('silent restore failed: $e');
    }
  }

  /// Make sure products are available. Safe to call at any time — it
  /// triggers [init] if it hasn't been called yet, waits for an in-flight
  /// init, or fires a fresh query if products are empty.
  Future<void> ensureProductsLoaded() async {
    if (products.isNotEmpty) return;

    if (!_initStarted) {
      await init();
      if (products.isNotEmpty) return;
      if (_state == SubState.unavailable) return;
    }

    if (_state == SubState.unavailable) return;

    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      await _initCompleter!.future;
      if (products.isNotEmpty) return;
      if (_state == SubState.unavailable) return;
    }

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    const maxAttempts = 3;
    IAPError? lastApiError;
    Object? lastException;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _log('queryProductDetails attempt $attempt/$maxAttempts');
        final response = await _iap.queryProductDetails(_productIds);

        if (response.error != null) {
          _log('query error: ${response.error}');
          lastApiError = response.error;
        }
        if (response.notFoundIDs.isNotEmpty) {
          _log('product IDs not found: ${response.notFoundIDs}');
        }

        products = response.productDetails;
        _log(
            'products loaded: ${products.map((p) => '${p.id}=${p.price}').join(', ')}');

        if (products.isNotEmpty) {
          _lastFailureDetails = null;
          _setState(SubState.ready);
          return;
        }
      } catch (e) {
        _log('queryProductDetails threw: $e');
        lastException = e;
      }

      if (attempt < maxAttempts) {
        final delay = Duration(milliseconds: 400 * attempt * attempt);
        await Future.delayed(delay);
      }
    }

    // All attempts produced empty products. Decide which event best describes
    // the failure: an explicit API error (network / agreement) vs. a clean
    // empty response (App Store Connect misconfiguration).
    if (lastApiError != null || lastException != null) {
      final details = lastApiError?.message ?? '$lastException';
      _lastFailureDetails = details;
      _emit(ProductsLoadFailedEvent(details));
    } else {
      _lastFailureDetails = null;
      _emit(const ProductsEmptyEvent());
    }
    _setState(SubState.noProducts);
  }

  // ---------------------------------------------------------------------------
  // Purchase flow
  // ---------------------------------------------------------------------------

  /// Initiates a purchase. The actual outcome is delivered asynchronously via
  /// the [events] stream (success / failure / cancellation / pending).
  Future<bool> buy(ProductDetails product) async {
    if (_state == SubState.unavailable) {
      _emit(const StoreUnavailableEvent());
      return false;
    }
    if (products.isEmpty) {
      _emit(const ProductsEmptyEvent());
      return false;
    }

    _setState(SubState.purchasing);
    try {
      final ok = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      _log('buyNonConsumable returned $ok for ${product.id}');
      if (!ok) {
        _lastFailureDetails = 'StoreKit rejected buy request';
        _emit(const PurchaseFailedEvent('StoreKit rejected buy request'));
        _setState(SubState.ready);
      }
      return ok;
    } catch (e) {
      _log('buyNonConsumable threw: $e');
      _lastFailureDetails = '$e';
      _emit(PurchaseFailedEvent('$e'));
      _setState(SubState.ready);
      return false;
    }
  }

  /// User-initiated restore. Waits [_restoreSettleWindow] after the request
  /// returns to collect `.restored` stream events, then emits a single
  /// [RestoreCompletedEvent] so the UI can report a definitive outcome.
  Future<void> restore() async {
    // Wait for init so the purchase stream listener is attached and the
    // store-availability check has run.
    if (!_initStarted || !(_initCompleter?.isCompleted ?? false)) {
      await init();
    }

    if (_state == SubState.unavailable) {
      _emit(const StoreUnavailableEvent());
      return;
    }

    _setState(SubState.restoring);
    _restoreInProgress = true;
    _restoreEventsSeen = 0;

    try {
      _log('restorePurchases (user-initiated)');
      await _iap.restorePurchases();
    } catch (e) {
      _log('restore threw: $e');
      _lastFailureDetails = '$e';
      _restoreInProgress = false;
      _setState(SubState.ready);
      _emit(RestoreFailedEvent('$e'));
      return;
    }

    // Give StoreKit a brief window to deliver any pending restored events.
    await Future.delayed(_restoreSettleWindow);

    final foundActive = _restoreEventsSeen > 0;
    _restoreInProgress = false;
    _setState(SubState.ready);
    _emit(RestoreCompletedEvent(foundActive: foundActive));
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    _log(
      'purchase update: id=${purchase.productID} status=${purchase.status} '
      'pendingComplete=${purchase.pendingCompletePurchase}',
    );

    switch (purchase.status) {
      case PurchaseStatus.pending:
        _emit(const PaymentPendingEvent());
        _setState(SubState.ready);
      case PurchaseStatus.purchased:
        _activatePremium(purchase);
        _emit(const PurchaseSuccessEvent());
        _setState(SubState.ready);
      case PurchaseStatus.restored:
        _activatePremium(purchase);
        if (_restoreInProgress) _restoreEventsSeen++;
        // Do NOT emit PurchaseSuccessEvent for silent/background restores —
        // only the user-initiated restore flow emits RestoreCompletedEvent,
        // and silent restores should not trigger UI.
        _setState(SubState.ready);
      case PurchaseStatus.error:
        _log('purchase error: ${purchase.error}');
        final details = purchase.error?.message ?? 'unknown';
        _lastFailureDetails = details;
        _emit(PurchaseFailedEvent(details));
        _setState(SubState.ready);
      case PurchaseStatus.canceled:
        _emit(const PurchaseCanceledEvent());
        _setState(SubState.ready);
    }

    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  void _activatePremium(PurchaseDetails purchase) {
    AuthService().setPremium(
      isPremium: true,
      planName: purchase.productID == weeklyId ? 'weekly' : 'yearly',
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ProductDetails? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _setState(SubState next) {
    if (_state == next) return;
    _state = next;
    _log('state → $next');
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _eventsController.close();
    super.dispose();
  }
}
