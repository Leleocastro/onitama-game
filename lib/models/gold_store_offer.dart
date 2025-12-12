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
      productIdentifier: 'gold_1000',
      displayName: '1,000 Gold',
      goldAmount: 1000,
    ),
    GoldBundleConfig(
      productIdentifier: 'gold_5000',
      displayName: '5,000 Gold',
      goldAmount: 5000,
    ),
    GoldBundleConfig(
      productIdentifier: 'gold_10000',
      displayName: '10,000 Gold',
      goldAmount: 10000,
      bonusAmount: 2500,
      featured: true,
      badge: GoldBundleBadge.mostPopular,
    ),
    GoldBundleConfig(
      productIdentifier: 'gold_25000',
      displayName: '25,000 Gold',
      goldAmount: 25000,
    ),
    GoldBundleConfig(
      productIdentifier: 'gold_50000',
      displayName: '50,000 Gold',
      goldAmount: 50000,
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
