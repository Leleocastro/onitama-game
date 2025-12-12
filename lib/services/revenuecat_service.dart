import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/gold_store_offer.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;
  bool _configured = false;
  bool _skipped = false;

  static const String _androidApiKey = 'goog_zGVlUtEItAMLhafwlJaabRFZPBx';
  static const String _iosApiKey = 'appl_mHiHZtCkHhkvJdOCHDUAEBUtfhC';

  Future<void> initialize() async {
    if (kIsWeb) {
      _skipped = true;
      return;
    }
    if (_configured || _skipped) return;
    final apiKey = _resolvePlatformKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[RevenueCat] Missing API key for current platform. Skipping configuration.');
      _skipped = true;
      return;
    }

    final initialUser = _auth.currentUser;
    final configuration = PurchasesConfiguration(apiKey)..appUserID = initialUser != null && !initialUser.isAnonymous ? initialUser.uid : null;

    await Purchases.configure(configuration);
    _configured = true;
    _authSubscription ??= _auth.authStateChanges().listen(_handleAuthChange);
  }

  Future<List<GoldStoreOffer>> fetchGoldOffers() async {
    _ensureReady();
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        throw StateError('No RevenueCat offering configured.');
      }
      final offers = current.availablePackages
          .map((package) {
            final config = GoldBundleCatalog.resolveFromPackage(package);
            if (config == null) return null;
            return GoldStoreOffer(package: package, config: config);
          })
          .whereType<GoldStoreOffer>()
          .toList();

      offers.sort((a, b) {
        if (a.isFeatured == b.isFeatured) {
          return a.totalGold.compareTo(b.totalGold);
        }
        return a.isFeatured ? -1 : 1;
      });

      if (offers.isEmpty) {
        throw StateError('No configured gold packages were returned by RevenueCat.');
      }
      return offers;
    } catch (e) {
      throw StateError('Failed to fetch RevenueCat offerings: $e');
    }
  }

  Future<CustomerInfo> purchaseOffer(GoldStoreOffer offer) async {
    _ensureReady();
    return Purchases.purchasePackage(offer.package);
  }

  Future<CustomerInfo> restorePurchases() async {
    _ensureReady();
    return Purchases.restorePurchases();
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  void _ensureReady() {
    if (_skipped || kIsWeb) {
      throw UnsupportedError('RevenueCat is not available on this platform.');
    }
    if (!_configured) {
      throw StateError('RevenueCat has not been configured yet.');
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    if (!_configured) return;
    if (user == null || user.isAnonymous) {
      await Purchases.logOut();
    } else {
      await Purchases.logIn(user.uid);
    }
  }

  String? _resolvePlatformKey() {
    if (Platform.isAndroid) return _androidApiKey;
    if (Platform.isIOS) return _iosApiKey;
    debugPrint('[RevenueCat] Unsupported platform ${Platform.operatingSystem}.');
    return null;
  }
}
