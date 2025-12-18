import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/skin_store_item.dart';
import '../models/theme_ownership.dart';
import '../models/user_profile.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';
import '../services/skin_store_service.dart';
import '../style/theme.dart';
import '../utils/extensions.dart';
import '../utils/skin_category_localizations.dart';
import 'gold_store_screen.dart';

class SkinItemDetailScreen extends StatefulWidget {
  SkinItemDetailScreen({
    required this.userId,
    required this.item,
    SkinStoreService? storeService,
    super.key,
  }) : storeService = storeService ?? SkinStoreService();

  final String userId;
  final SkinStoreItem item;
  final SkinStoreService storeService;

  @override
  State<SkinItemDetailScreen> createState() => _SkinItemDetailScreenState();
}

class _SkinItemDetailScreenState extends State<SkinItemDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<UserProfile?> _profileStream;
  late final Stream<ThemeOwnership> _ownershipStream;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _profileStream = _firestoreService.watchUserProfile(widget.userId);
    _ownershipStream = widget.storeService.watchOwnership(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF0B0008), Color(0xFF1C0018), Color(0xFF2C0033)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: StreamBuilder<UserProfile?>(
            stream: _profileStream,
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              if (profileSnapshot.connectionState == ConnectionState.waiting && profile == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              return StreamBuilder<ThemeOwnership>(
                stream: _ownershipStream,
                builder: (context, ownershipSnapshot) {
                  final ownership = ownershipSnapshot.data ?? ThemeOwnership.empty();
                  final owned = widget.item.isOwned(ownership);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 160),
                          child: _DetailContent(
                            item: widget.item,
                            owned: owned,
                            l10n: l10n,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: _PurchaseButton(
                          owned: owned,
                          isProcessing: _isProcessing,
                          l10n: l10n,
                          priceLabel: NumberFormat.decimalPattern(l10n.localeName).format(widget.item.finalPrice),
                          onPressed: owned || profile == null || _isProcessing ? null : () => _handlePurchase(profile),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(UserProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final price = widget.item.finalPrice;
    final formatter = NumberFormat.decimalPattern(l10n.localeName);

    if (profile.goldBalance < price) {
      context.toToastError(l10n.skinStoreInsufficientGold);
      _openGoldStore();
      return;
    }

    final remaining = profile.goldBalance - price;
    unawaited(AudioService.instance.playUiConfirmSound());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skinStoreConfirmTitle),
        content: Text(
          l10n.skinStoreConfirmDescription(
            widget.item.name,
            formatter.format(price),
            formatter.format(remaining),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.skinStoreBuyButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await widget.storeService.purchaseItem(themeId: widget.item.themeId, valueId: widget.item.id);
      if (!mounted) return;
      context.toToastSuccess(l10n.skinStorePurchaseSuccess(widget.item.name));
      final shouldEquip = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.skinStoreEquipPromptTitle),
          content: Text(l10n.skinStoreEquipPromptDescription(widget.item.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.skinStoreEquipLater),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.skinStoreEquipConfirm),
            ),
          ],
        ),
      );
      if (shouldEquip == true && mounted) {
        await widget.storeService.equipAssets(
          userId: widget.userId,
          themeId: widget.item.themeId,
          assetIds: widget.item.assetIds,
        );
        if (!mounted) return;
        context.toToastSuccess(l10n.skinStoreEquipSuccess(widget.item.name));
      }
    } on ThemePurchaseException catch (error) {
      if (!mounted) return;
      switch (error.code) {
        case ThemePurchaseError.insufficientFunds:
          context.toToastError(l10n.skinStoreInsufficientGold);
          _openGoldStore();
          break;
        case ThemePurchaseError.alreadyOwned:
          context.toToastError(l10n.skinStoreOwnedMessage);
          break;
        default:
          context.toToastError(error.message);
          break;
      }
    } catch (error) {
      if (mounted) {
        context.toToastError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _openGoldStore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoldStoreScreen(userId: widget.userId)),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.item, required this.owned, required this.l10n});

  final SkinStoreItem item;
  final bool owned;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(l10n.localeName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: item.imageUrl.isEmpty
                ? Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 48),
                  )
                : CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 48),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
          child: Text(
            item.category.label(l10n),
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.name,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          item.description.isEmpty ? item.themeDescription : item.description,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.08),
                radius: 28,
                child: Image.asset('assets/icons/coins.png', width: 32, height: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.skinStoreDetailPriceLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatter.format(item.finalPrice),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (item.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.skinStoreDiscountLabel(formatter.format(item.savings)),
                            style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (owned) ...[
          const SizedBox(height: 16),
          Text(
            l10n.skinStoreOwnedMessage,
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          l10n.skinStoreDetailAssetsTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (item.assetIds.isEmpty)
          Text(l10n.skinStoreEmptyAssets, style: const TextStyle(color: Colors.white54))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final assetId in item.assetIds)
                _AssetPreviewTile(
                  imageUrl: item.assetPreviewUrls[assetId],
                ),
            ],
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _AssetPreviewTile extends StatelessWidget {
  const _AssetPreviewTile({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl == null || imageUrl!.isEmpty) {
      child = const Icon(Icons.extension, color: Colors.black38, size: 32);
    } else {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => const Icon(Icons.extension_off, color: Colors.black38, size: 32),
      );
    }
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.owned,
    required this.isProcessing,
    required this.l10n,
    required this.priceLabel,
    required this.onPressed,
  });

  final bool owned;
  final bool isProcessing;
  final AppLocalizations l10n;
  final String priceLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: owned ? Colors.white10 : AppTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      onPressed: owned ? null : onPressed,
      child: isProcessing
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!owned) ...[
                  Image.asset('assets/icons/coins.png', width: 22, height: 22),
                  const SizedBox(width: 10),
                  Text(
                    priceLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  owned ? l10n.skinStoreOwnedButton : l10n.skinStoreBuyButton,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}
