import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:meal_tracker/core/services/auth_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String weeklyId = 'weekly_premium';
  static const String yearlyId = 'yearly_premium';
  static const Set<String> _productIds = {weeklyId, yearlyId};

  List<ProductDetails> products = [];
  bool isAvailable = false;

  static const Set<String> _storePlans = {'weekly', 'yearly'};

  Future<void> init() async {
    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        debugPrint('SubscriptionService: store not available');
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (error) =>
            debugPrint('SubscriptionService: stream error $error'),
      );

      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('SubscriptionService: query error ${response.error}');
      }
      products = response.productDetails;

      final auth = AuthService();
      if (auth.isPremium && _storePlans.contains(auth.planName)) {
        await auth.setPremium(isPremium: false, planName: auth.planName);
      }

      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('SubscriptionService.init failed: $e');
    }
  }

  Future<bool> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<bool> restore() async {
    if (!isAvailable) return false;
    await _iap.restorePurchases();
    return true;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      _activatePremium(purchase);
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

  void dispose() {
    _subscription?.cancel();
  }
}
