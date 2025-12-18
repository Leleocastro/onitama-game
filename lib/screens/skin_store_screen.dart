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
import '../utils/skin_category_localizations.dart';
import 'gold_store_screen.dart';
import 'skin_item_detail_screen.dart';

class SkinStoreScreen extends StatefulWidget {
  const SkinStoreScreen({required this.userId, super.key});

  final String userId;

  @override
  State<SkinStoreScreen> createState() => _SkinStoreScreenState();
}

class _SkinStoreScreenState extends State<SkinStoreScreen> {
  final SkinStoreService _skinStoreService = SkinStoreService();
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<SkinStoreItem>> _itemsFuture;
  late final Stream<UserProfile?> _profileStream;
  late final Stream<ThemeOwnership> _ownershipStream;
  SkinCategory _selectedCategory = SkinCategory.pieces;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _skinStoreService.fetchStoreItems();
    _profileStream = _firestoreService.watchUserProfile(widget.userId);
    _ownershipStream = _skinStoreService.watchOwnership(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradient = const LinearGradient(
      colors: [Color(0xFF10000D), Color(0xFF1B0022), Color(0xFF2F0033)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: StreamBuilder<UserProfile?>(
            stream: _profileStream,
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                l10n.skinStoreTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.skinStoreSubtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        _GoldBadge(
                          balance: profile?.goldBalance ?? 0,
                          onTapAdd: _openGoldStore,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CategorySelector(
                    selected: _selectedCategory,
                    onSelected: _changeCategory,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<SkinStoreItem>>(
                      future: _itemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _LoadingState(label: l10n.skinStoreLoading);
                        }
                        if (snapshot.hasError) {
                          return _ErrorState(
                            message: l10n.skinStoreError,
                            buttonLabel: l10n.skinStoreRetry,
                            onRetry: _refreshItems,
                          );
                        }
                        final items = snapshot.data ?? const <SkinStoreItem>[];
                        if (items.isEmpty) {
                          return _EmptyState(label: l10n.skinStoreEmpty, onRetry: _refreshItems, retryLabel: l10n.skinStoreRetry);
                        }
                        return StreamBuilder<ThemeOwnership>(
                          stream: _ownershipStream,
                          builder: (context, ownershipSnapshot) {
                            final ownership = ownershipSnapshot.data ?? ThemeOwnership.empty();
                            final visible = items.where((item) => item.matchesCategory(_selectedCategory)).toList();
                            if (visible.isEmpty) {
                              return _EmptyState(label: l10n.skinStoreFilterEmpty, onRetry: _refreshItems, retryLabel: l10n.skinStoreRetry);
                            }
                            return RefreshIndicator(
                              onRefresh: _refreshItems,
                              edgeOffset: 20,
                              color: AppTheme.primary,
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                itemCount: visible.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 18,
                                  crossAxisSpacing: 18,
                                  childAspectRatio: 0.78,
                                ),
                                itemBuilder: (context, index) {
                                  final item = visible[index];
                                  final owned = item.isOwned(ownership);
                                  final equipped = item.isEquipped(profile);
                                  return _StoreItemCard(
                                    item: item,
                                    owned: owned,
                                    equipped: equipped,
                                    onTap: () => _openDetail(item),
                                    l10n: l10n,
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshItems() async {
    setState(() {
      _itemsFuture = _skinStoreService.fetchStoreItems();
    });
    await _itemsFuture;
  }

  void _changeCategory(SkinCategory category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
  }

  void _openGoldStore() {
    unawaited(AudioService.instance.playUiConfirmSound());
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoldStoreScreen(userId: widget.userId)),
    );
  }

  void _openDetail(SkinStoreItem item) {
    unawaited(AudioService.instance.playUiConfirmSound());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkinItemDetailScreen(
          userId: widget.userId,
          item: item,
          storeService: _skinStoreService,
        ),
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  const _GoldBadge({required this.balance, required this.onTapAdd});

  final int balance;
  final VoidCallback onTapAdd;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.compact(locale: AppLocalizations.of(context)!.localeName);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Image.asset('assets/icons/coins.png', width: 20, height: 20),
                const SizedBox(width: 6),
                Text(
                  formatter.format(balance),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTapAdd,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.selected, required this.onSelected, required this.l10n});

  final SkinCategory selected;
  final ValueChanged<SkinCategory> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const categories = [
      SkinCategory.pieces,
      SkinCategory.boards,
      SkinCategory.cards,
      SkinCategory.backgrounds,
      SkinCategory.group,
      SkinCategory.all,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final category in categories) ...[
            _CategoryPill(
              label: category.label(l10n),
              isSelected: selected == category,
              onTap: () => onSelected(category),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({required this.item, required this.owned, required this.equipped, required this.onTap, required this.l10n});

  final SkinStoreItem item;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern(l10n.localeName);
    final priceLabel = formatter.format(item.finalPrice);
    final originalPriceLabel = formatter.format(item.price);
    final savings = formatter.format(item.savings);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF1e0b1a),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: item.imageUrl.isEmpty
                            ? Container(
                                color: Colors.white.withOpacity(0.05),
                                child: const Icon(Icons.image_not_supported, color: Colors.white38),
                              )
                            : CachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) => Container(
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.white.withOpacity(0.05),
                                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    if (owned)
                      Text(
                        l10n.skinStoreOwnedTag,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      )
                    else
                      Row(
                        children: [
                          Image.asset('assets/icons/coins.png', width: 18, height: 18),
                          const SizedBox(width: 6),
                          if (item.hasDiscount) ...[
                            Text(
                              originalPriceLabel,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            priceLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // if (owned)
              //   Positioned(
              //     top: 12,
              //     left: 12,
              //     child: _StatusChip(label: l10n.skinStoreOwnedTag, color: Colors.white.withOpacity(0.2)),
              //   ),
              if (equipped)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatusChip(label: l10n.skinStoreEquippedTag, color: Colors.greenAccent.withOpacity(0.2)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label, required this.onRetry, required this.retryLabel});

  final String label;
  final Future<void> Function()? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                onRetry?.call();
              },
              child: Text(retryLabel),
            ),
          ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              onRetry();
            },
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
