import '../l10n/app_localizations.dart';
import '../models/skin_store_item.dart';

extension SkinCategoryLocalization on SkinCategory {
  String label(AppLocalizations l10n) {
    switch (this) {
      case SkinCategory.pieces:
        return l10n.skinStoreCategoryPieces;
      case SkinCategory.boards:
        return l10n.skinStoreCategoryBoards;
      case SkinCategory.cards:
        return l10n.skinStoreCategoryCards;
      case SkinCategory.backgrounds:
        return l10n.skinStoreCategoryBackgrounds;
      case SkinCategory.group:
        return l10n.skinStoreCategoryGroup;
      case SkinCategory.all:
        return l10n.skinStoreCategoryAll;
    }
  }
}
