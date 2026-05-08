import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  // Premium flags
  static const String _premiumKey = 'premium_access';
  static const String _lifetimeKey = 'lifetime_access';
  static const String _subscriptionActiveKey = 'subscription_active';

  // Free trial keys
  static const String _trialStartMillisKey = 'trial_start_millis';
  static const String _trialUsedKey = 'trial_used_once';
  static const int _trialDays = 7;

  // Product IDs
  static final Set<String> _kIds = <String>{
    // NOTE: Assurez-vous de créer ces produits dans App Store Connect
    // et Google Play Console avec une période d'essai gratuite de 7 jours.
    // Les identifiants doivent correspondre exactement.
    'lifetime_premium',
    'premium_monthly',
    'premium_annual',
  };

  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Initialization
  static Future<bool> initializePurchases() async {
    // Skip IAP initialization on web/unsupported platforms to avoid runtime errors
    if (kIsWeb) {
      // ignore: avoid_print
      print('[SubscriptionService] Web detected: skipping IAP init');
      return false;
    }
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) return false;
    initializePurchaseListener();
    return true;
  }

  // Products
  static Future<List<ProductDetails>> getProducts() async {
    try {
      final response = await InAppPurchase.instance.queryProductDetails(_kIds);
      if (response.notFoundIDs.isNotEmpty) {
        // ignore: avoid_print
        print('Produits non trouvés: ${response.notFoundIDs}');
      }
      return response.productDetails;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la récupération des produits: $e');
      return [];
    }
  }

  static Future<Map<String, ProductDetails>> getProductsMap() async {
    final products = await getProducts();
    final Map<String, ProductDetails> productsMap = {};
    for (final product in products) {
      productsMap[product.id] = product;
    }
    return productsMap;
  }

  // Purchase
  static Future<bool> purchasePlan(String productId) async {
    try {
      final response = await InAppPurchase.instance.queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        throw Exception('Produit non trouvé: $productId');
      }
      final productDetails = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      // Les abonnements et les achats à vie (non-consommables) utilisent buyNonConsumable
      final purchaseResult = await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      return purchaseResult;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de l\'achat: $e');
      return false;
    }
  }

  // Premium status (includes trial)
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    // Lifetime or paid subscription always premium
    if (prefs.getBool(_lifetimeKey) == true || prefs.getBool(_subscriptionActiveKey) == true) {
      await _setPremiumStatus(true);
      return true;
    }
    // Trial active?
    final now = DateTime.now();
    final startMillis = prefs.getInt(_trialStartMillisKey);
    if (startMillis != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
      final end = start.add(Duration(days: _trialDays));
      if (now.isBefore(end)) {
        await _setPremiumStatus(true);
        return true;
      } else {
        // Trial expired -> revoke premium if no paid access
        await _setPremiumStatus(false);
        return false;
      }
    }
    // Fallback to stored premium flag
    return prefs.getBool(_premiumKey) ?? false;
  }

  static Future<bool> isLifetime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lifetimeKey) ?? false;
  }

  static Future<bool> hasActiveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_subscriptionActiveKey) ?? false;
  }

  // Trial helpers
  static Future<bool> isTrialActive() async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt(_trialStartMillisKey);
    if (startMillis == null) return false;
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    return DateTime.now().isBefore(start.add(Duration(days: _trialDays)));
  }

  static Future<bool> isTrialUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trialUsedKey) ?? false;
  }

  static Future<int> trialDaysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt(_trialStartMillisKey);
    if (startMillis == null) return 0;
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final end = start.add(Duration(days: _trialDays));
    final now = DateTime.now();
    if (now.isAfter(end)) return 0;
    return end.difference(now).inDays + (end.difference(now).inHours % 24 > 0 ? 1 : 0);
  }

  static Future<void> startFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getBool(_trialUsedKey) ?? false;
    if (used) return; // One-time trial only
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_trialStartMillisKey, nowMillis);
    await prefs.setBool(_trialUsedKey, true);
    await _setPremiumStatus(true);
  }

  static Future<void> endTrialIfExpired() async {
    final active = await isTrialActive();
    if (!active) {
      final hasPaid = await isLifetime() || await hasActiveSubscription();
      if (!hasPaid) await _setPremiumStatus(false);
    }
  }

  // State persistence helpers
  static Future<void> _setPremiumStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, status);
  }

  static Future<void> _setLifetimeStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lifetimeKey, status);
  }


  // Restore & verify
  static Future<void> restorePurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la restauration des achats: $e');
    }
  }

  static Future<bool> verifySubscriptionStatus() async {
    try {
      await InAppPurchase.instance.restorePurchases();
      await Future.delayed(const Duration(seconds: 2));
      await endTrialIfExpired();
      return isPremium();
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la vérification du statut d\'abonnement: $e');
      return false;
    }
  }

  // Listener
  static void initializePurchaseListener() {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        // ignore: avoid_print
        print('Erreur du flux d\'achats: $error');
      },
    );
  }

  static void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      // ignore: avoid_print
      print('Statut de l\'achat: ${purchaseDetails.status} pour ${purchaseDetails.productID}');
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        _verifyAndDeliverProduct(purchaseDetails);
      }
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  static Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    // ignore: avoid_print
    print('Activation des fonctionnalités premium pour: ${purchaseDetails.productID}');
    try {
      await _setPremiumStatus(true);
      if (purchaseDetails.productID == 'lifetime_premium') {
        await _setLifetimeStatus(true);
        // ignore: avoid_print
        print('Accès à vie activé');
      } else if (purchaseDetails.productID == 'premium_monthly' || purchaseDetails.productID == 'premium_annual') {
        await _setSubscriptionActive(true);
        // ignore: avoid_print
        print('Abonnement actif (${purchaseDetails.productID})');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de l\'activation du produit: $e');
    }
  }

  static void dispose() {
    _subscription?.cancel();
  }

  // --- Private helpers ---
  static Future<void> _setSubscriptionActive(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionActiveKey, status);
  }
}