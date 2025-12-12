import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/errors.dart';

import '../l10n/app_localizations.dart';
import '../models/gold_store_offer.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/revenuecat_service.dart';
import '../style/theme.dart';

class GoldStoreScreen extends StatefulWidget {
  const GoldStoreScreen({required this.userId, super.key});

  final String userId;

  @override
  State<GoldStoreScreen> createState() => _GoldStoreScreenState();
}

class _GoldStoreScreenState extends State<GoldStoreScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<GoldStoreOffer>> _offersFuture;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _offersFuture = _loadOffers();
  }

  Future<List<GoldStoreOffer>> _loadOffers() {
    return RevenueCatService.instance.fetchGoldOffers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bgGradient = const LinearGradient(
      colors: [Color(0xFF05000a), Color(0xFF1b0015)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      splashRadius: 24,
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l10n.goldStoreTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.goldStoreSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<UserProfile?>(
                      stream: _firestoreService.watchUserProfile(widget.userId),
                      builder: (context, snapshot) {
                        final balance = snapshot.data?.goldBalance ?? 0;
                        return _GoldChip(balance: balance, label: l10n.goldBalanceLabel);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<GoldStoreOffer>>(
                  future: _offersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _LoadingState(label: l10n.goldStoreLoading);
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: l10n.goldStoreError,
                        buttonLabel: l10n.goldStoreRetry,
                        onRetry: _refreshOffers,
                      );
                    }
                    final offers = snapshot.data ?? const <GoldStoreOffer>[];
                    if (offers.isEmpty) {
                      return _ErrorState(
                        message: l10n.goldStoreError,
                        buttonLabel: l10n.goldStoreRetry,
                        onRetry: _refreshOffers,
                      );
                    }
                    final featured = offers.firstWhere((offer) => offer.isFeatured, orElse: () => offers.first);
                    final others = offers.where((offer) => offer != featured).toList();
                    return RefreshIndicator(
                      onRefresh: () async {
                        final future = _refreshOffers();
                        await future;
                      },
                      edgeOffset: 24,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                              child: _FeaturedCard(
                                offer: featured,
                                isBusy: _isPurchasing,
                                onPressed: () => _handlePurchase(featured),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.92,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final offer = others[index];
                                  return _GridOfferTile(
                                    offer: offer,
                                    isBusy: _isPurchasing,
                                    onPressed: () => _handlePurchase(offer),
                                  );
                                },
                                childCount: others.length,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: _isPurchasing ? null : _restorePurchases,
                                  icon: const Icon(Icons.refresh, color: Colors.white70),
                                  label: Text(l10n.goldStoreRestoreButton, style: const TextStyle(color: Colors.white70)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(GoldStoreOffer offer) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await RevenueCatService.instance.purchaseOffer(offer);
      await _firestoreService.creditGoldFromStorePurchase(
        uid: widget.userId,
        amount: offer.totalGold,
        packageIdentifier: offer.productIdentifier,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goldStorePurchaseSuccess)),
      );
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        // Ignore cancellations.
      } else {
        _showPurchaseError(l10n.goldStorePurchaseError);
      }
    } catch (_) {
      _showPurchaseError(l10n.goldStorePurchaseError);
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await RevenueCatService.instance.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.goldStorePurchaseSuccess)),
      );
    } catch (_) {
      _showPurchaseError(l10n.goldStorePurchaseError);
    }
  }

  Future<void> _refreshOffers() {
    setState(() {
      _offersFuture = _loadOffers();
    });
    return _offersFuture;
  }

  void _showPurchaseError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _GoldChip extends StatelessWidget {
  const _GoldChip({required this.balance, required this.label});

  final int balance;
  final String label;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(AppLocalizations.of(context)!.localeName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icons/coins.png', width: 20, height: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                formatter.format(balance),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.offer, required this.onPressed, required this.isBusy});

  final GoldStoreOffer offer;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final bonusLabel = offer.hasBonus ? l10n.goldStoreBonusLabel(numberFormat.format(offer.bonusAmount)) : null;
    final badgeText = offer.badge == GoldBundleBadge.mostPopular ? l10n.goldStoreBadgeMostPopular : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B0E4E), Color(0xFFff1979)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (badgeText != null)
            Align(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: const TextStyle(color: Color(0xFFc50740), fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            radius: 36,
            child: Image.asset('assets/icons/coins.png', width: 48, height: 48),
          ),
          const SizedBox(height: 16),
          Text(
            offer.config.displayName,
            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            offer.package.storeProduct.priceString,
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
          ),
          if (bonusLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${bonusLabel.toUpperCase()}!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFc50740),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: isBusy ? null : onPressed,
              child: Text(
                l10n.goldStoreBuyButton,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridOfferTile extends StatelessWidget {
  const _GridOfferTile({required this.offer, required this.onPressed, required this.isBusy});

  final GoldStoreOffer offer;
  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final bonusLabel = offer.hasBonus ? l10n.goldStoreBonusLabel(numberFormat.format(offer.bonusAmount)) : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1f0d17),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              offer.config.displayName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              offer.package.storeProduct.priceString,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
            ),
            if (bonusLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ $bonusLabel',
                  style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w700),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3d0c1d),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: isBusy ? null : onPressed,
                child: Text(l10n.goldStoreBuyButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.buttonLabel, required this.onRetry});

  final String message;
  final String buttonLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
