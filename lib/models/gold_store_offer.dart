import 'package:purchases_flutter/purchases_flutter.dart';

/// Static catalog describing how much gold each RevenueCat product should grant.
enum GoldBundleBadge {
  mostPopular,
  bestValue,
}

class GoldBundleConfig {
  const GoldBundleConfig({
    required this.productIdentifier,
    required this.goldAmount,
    required this.displayName,
    this.badge,
    this.bonusAmount = 0,
    this.featured = false,
  });

  final String productIdentifier;
  final int goldAmount;
  final int bonusAmount;
  final String displayName;
  final GoldBundleBadge? badge;
  final bool featured;

  int get totalGold => goldAmount + bonusAmount;
}

class GoldStoreOffer {
  const GoldStoreOffer({required this.package, required this.config});

  final Package package;
  final GoldBundleConfig config;

  String get productIdentifier => package.storeProduct.identifier;
  String get priceText => package.storeProduct.priceString;
  bool get hasBonus => config.bonusAmount > 0;
  int get bonusAmount => config.bonusAmount;
  int get goldAmount => config.goldAmount;
  int get totalGold => config.totalGold;
  bool get isFeatured => config.featured;
  GoldBundleBadge? get badge => config.badge;
}

/// Catalog of known consumable products. Keep identifiers in sync with RevenueCat.
class GoldBundleCatalog {
  static const List<GoldBundleConfig> _bundles = [
    GoldBundleConfig(
      productIdentifier: 'com.ltag.onitama.gold_1000',
      displayName: '1000 Gold',
      goldAmount: 1000,
      featured: true,
    ),
    GoldBundleConfig(
      productIdentifier: 'com.ltag.onitama.gold_5000',
      displayName: '5000 Gold',
      goldAmount: 5000,
      badge: GoldBundleBadge.bestValue,
    ),
    GoldBundleConfig(
      productIdentifier: 'com.ltag.onitama.gold_2000',
      displayName: '2000 Gold',
      goldAmount: 2000,
      badge: GoldBundleBadge.mostPopular,
    ),
    GoldBundleConfig(
      productIdentifier: 'com.ltag.onitama.gold_500',
      displayName: '500 Gold',
      goldAmount: 500,
    ),
  ];

  static GoldBundleConfig? resolveFromPackage(Package package) {
    final id = package.storeProduct.identifier;
    for (final bundle in _bundles) {
      if (bundle.productIdentifier == id) {
        return bundle;
      }
    }
    return null;
  }

  static Iterable<GoldBundleConfig> get bundles => _bundles;
}
