import 'theme_model.dart';
import 'theme_ownership.dart';
import 'user_profile.dart';

enum SkinCategory { pieces, boards, cards, backgrounds, group, all }

extension SkinCategoryX on SkinCategory {
  String get translationKey {
    switch (this) {
      case SkinCategory.pieces:
        return 'skinStoreCategoryPieces';
      case SkinCategory.boards:
        return 'skinStoreCategoryBoards';
      case SkinCategory.cards:
        return 'skinStoreCategoryCards';
      case SkinCategory.backgrounds:
        return 'skinStoreCategoryBackgrounds';
      case SkinCategory.group:
        return 'skinStoreCategoryGroup';
      case SkinCategory.all:
        return 'skinStoreCategoryAll';
    }
  }

  static SkinCategory fromType(String type) {
    final value = type.toLowerCase();
    switch (value) {
      case 'piece':
      case 'pieces':
        return SkinCategory.pieces;
      case 'board':
      case 'boards':
        return SkinCategory.boards;
      case 'card':
      case 'cards':
        return SkinCategory.cards;
      case 'background':
      case 'backgrounds':
        return SkinCategory.backgrounds;
      case 'group':
      case 'bundle':
      case 'bundles':
        return SkinCategory.group;
      default:
        return SkinCategory.all;
    }
  }
}

class SkinStoreItem {
  SkinStoreItem({
    required this.id,
    required this.themeId,
    required this.themeName,
    required this.themeDescription,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.assetIds,
    required this.assetPreviewUrls,
    required this.price,
    required this.discount,
  });

  factory SkinStoreItem.fromTheme({required ThemeModel theme, required ThemeVariantModel variant}) {
    final previews = <String, String>{};
    for (final asset in variant.assets) {
      final url = theme.assets[asset];
      if (url != null && url.isNotEmpty) {
        previews[asset] = url;
      }
    }

    var fallbackImage = '';
    for (final url in theme.assets.values) {
      if (url.isNotEmpty) {
        fallbackImage = url;
        break;
      }
    }

    return SkinStoreItem(
      id: variant.id,
      themeId: theme.id,
      themeName: theme.name,
      themeDescription: theme.description ?? '',
      name: variant.name,
      description: variant.description.isNotEmpty ? variant.description : (theme.description ?? ''),
      imageUrl: variant.imageUrl.isNotEmpty ? variant.imageUrl : fallbackImage,
      category: SkinCategoryX.fromType(variant.type),
      assetIds: List.unmodifiable(variant.assets),
      assetPreviewUrls: Map.unmodifiable(previews),
      price: variant.value,
      discount: variant.discount,
    );
  }

  final String id;
  final String themeId;
  final String themeName;
  final String themeDescription;
  final String name;
  final String description;
  final String imageUrl;
  final SkinCategory category;
  final List<String> assetIds;
  final Map<String, String> assetPreviewUrls;
  final int price;
  final double discount;

  int get finalPrice {
    final computed = (price * (1 - discount)).round();
    if (computed < 0) return 0;
    if (computed > price) return price;
    return computed;
  }

  int get savings => price - finalPrice;
  bool get hasDiscount => discount > 0;

  bool matchesCategory(SkinCategory selected) {
    if (selected == SkinCategory.all) return true;
    return category == selected;
  }

  bool isOwned(ThemeOwnership ownership) => ownership.ownsAll(themeId, assetIds);

  bool isEquipped(UserProfile? profile) {
    if (profile == null || profile.theme.isEmpty) return false;
    for (final assetId in assetIds) {
      if (profile.theme[assetId] != themeId) {
        return false;
      }
    }
    return assetIds.isNotEmpty;
  }
}
