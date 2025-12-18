import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_model.dart';
import '../models/point.dart';
import '../models/theme_model.dart';
import '../models/theme_ownership.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/skin_store_service.dart';
import '../services/theme_manager.dart';
import '../services/theme_service.dart';
import '../utils/extensions.dart';
import '../widgets/card_widget.dart';

class SkinLoadoutScreen extends StatefulWidget {
  const SkinLoadoutScreen({required this.userId, super.key});

  final String userId;

  @override
  State<SkinLoadoutScreen> createState() => _SkinLoadoutScreenState();
}

class _SkinLoadoutScreenState extends State<SkinLoadoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final SkinStoreService _skinStoreService = SkinStoreService();
  final ThemeService _themeService = ThemeService();

  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<ThemeOwnership>? _ownershipSubscription;

  bool _loadingThemes = true;
  Object? _themeError;
  _ThemeBundle? _themeBundle;

  UserProfile? _profile;
  ThemeOwnership _ownership = ThemeOwnership.empty();
  Map<String, String> _workingSelection = <String, String>{};
  Map<String, String> _lastSavedSelection = <String, String>{};
  Map<String, String> _passthroughAssignments = <String, String>{};
  bool _saving = false;
  SkinSlotCategory _selectedCategory = SkinSlotCategory.pieces;

  static final List<CardModel> _previewCards = _buildReferenceCards();

  @override
  void initState() {
    super.initState();
    _loadThemes();
    _profileSubscription = _firestoreService.watchUserProfile(widget.userId).listen(_onProfileChanged);
    _ownershipSubscription = _skinStoreService.watchOwnership(widget.userId).listen((ownership) {
      if (!mounted) return;
      setState(() => _ownership = ownership);
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _ownershipSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadThemes() async {
    setState(() {
      _loadingThemes = true;
      _themeError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _themeService.fetchAvailableThemes(),
        _themeService.fetchCurrentThemeId(),
      ]);
      final themes = (results.first as List<ThemeModel>).where((theme) => theme.enabled).toList();
      final remoteDefault = results.last as String?;
      final fallbackId = remoteDefault?.isNotEmpty == true
          ? remoteDefault!
          : themes.isNotEmpty
              ? themes.first.id
              : ThemeManager.currentThemeId;
      if (!mounted) return;
      setState(() {
        _themeBundle = _ThemeBundle(themes: themes, defaultThemeId: fallbackId);
        _loadingThemes = false;
      });
      _initializeSelectionIfPossible();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingThemes = false;
        _themeError = error;
      });
    }
  }

  void _onProfileChanged(UserProfile? profile) {
    if (!mounted) return;
    setState(() => _profile = profile);
    _initializeSelectionIfPossible();
  }

  void _initializeSelectionIfPossible() {
    if (_themeBundle == null || _profile == null) {
      return;
    }
    if (_workingSelection.isNotEmpty && _isDirty) {
      return;
    }
    final defaultThemeId = _themeBundle!.defaultThemeId;
    final serverAssignments = Map<String, String>.from(_profile?.theme ?? const <String, String>{});
    _passthroughAssignments = Map<String, String>.from(serverAssignments)..removeWhere((key, _) => _slotAssetIds.contains(key));
    final nextSelection = <String, String>{};
    for (final slot in _skinSlots) {
      nextSelection[slot.assetId] = serverAssignments[slot.assetId] ?? defaultThemeId;
    }
    if (!mounted) return;
    setState(() {
      _workingSelection = nextSelection;
      _lastSavedSelection = Map<String, String>.from(nextSelection);
    });
  }

  bool get _isDirty => !mapEquals(_workingSelection, _lastSavedSelection);

  Future<void> _saveSelection() async {
    if (_themeBundle == null || !_isDirty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, String>{
        ..._passthroughAssignments,
        ..._workingSelection,
      };
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set(
        {'theme': payload},
        SetOptions(merge: true),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastSavedSelection = Map<String, String>.from(_workingSelection);
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.skinLoadoutSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.skinLoadoutApplyError),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _resetToDefault() {
    if (_themeBundle == null) return;
    setState(() {
      for (final slot in _skinSlots) {
        _workingSelection[slot.assetId] = _themeBundle!.defaultThemeId;
      }
    });
  }

  void _selectThemeForSlot(String assetId, String themeId) {
    final current = _workingSelection[assetId];
    if (current == themeId) return;
    setState(() {
      _workingSelection = Map<String, String>.from(_workingSelection)..[assetId] = themeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bundle = _themeBundle;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.skinLoadoutTitle),
          actions: [
            TextButton(
              onPressed: (_saving || !_isDirty) ? null : _saveSelection,
              child: _saving
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.skinLoadoutSaving),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.save_outlined),
                        const SizedBox(width: 6),
                        Text(l10n.skinLoadoutSave),
                      ],
                    ),
            ),
            TextButton(
              onPressed: (_saving || bundle == null) ? null : _resetToDefault,
              child: Text(l10n.skinLoadoutReset),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.skinLoadoutSelectionTab),
              Tab(text: l10n.skinLoadoutPreviewTab),
            ],
          ),
        ),
        body: _buildBody(context, l10n, bundle),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    _ThemeBundle? bundle,
  ) {
    if (_loadingThemes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_themeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.skinLoadoutUnableToLoad),
            12.0.spaceY,
            FilledButton.icon(
              onPressed: _loadThemes,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.skinLoadoutRetry),
            ),
          ],
        ),
      );
    }
    if (bundle == null) {
      return Center(child: Text(l10n.skinLoadoutUnavailable));
    }

    final resolver = _ThemePreviewResolver(bundle, _workingSelection);
    return TabBarView(
      children: [
        _buildSelectionView(l10n, bundle),
        _SkinPreviewPane(
          l10n: l10n,
          resolver: resolver,
          cards: _previewCards,
        ),
      ],
    );
  }

  Widget _buildSelectionView(AppLocalizations l10n, _ThemeBundle bundle) {
    final selector = _SkinSlotSelector(
      l10n: l10n,
      selectedCategory: _selectedCategory,
      onCategoryChanged: (category) => setState(() => _selectedCategory = category),
      workingSelection: _workingSelection,
      ownership: _ownership,
      bundle: bundle,
      onSelectTheme: _selectThemeForSlot,
    );

    return Column(
      children: [
        if (_isDirty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(l10n.skinLoadoutUnsavedBanner),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: selector,
          ),
        ),
      ],
    );
  }
}

class _SkinSlotSelector extends StatelessWidget {
  const _SkinSlotSelector({
    required this.l10n,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.workingSelection,
    required this.ownership,
    required this.bundle,
    required this.onSelectTheme,
  });

  final AppLocalizations l10n;
  final SkinSlotCategory selectedCategory;
  final ValueChanged<SkinSlotCategory> onCategoryChanged;
  final Map<String, String> workingSelection;
  final ThemeOwnership ownership;
  final _ThemeBundle bundle;
  final void Function(String assetId, String themeId) onSelectTheme;

  @override
  Widget build(BuildContext context) {
    final categorySlots = _skinSlots.where((slot) => slot.category == selectedCategory).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.skinLoadoutSubtitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        16.0.spaceY,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SkinSlotCategory.values
              .map(
                (category) => ChoiceChip(
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  label: Text(_categoryLabel(l10n, category)),
                  selected: category == selectedCategory,
                  onSelected: (_) => onCategoryChanged(category),
                ),
              )
              .toList(),
        ),
        24.0.spaceY,
        if (categorySlots.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.skinLoadoutEmptyCategory),
            ),
          )
        else
          ...categorySlots.map((slot) {
            final options = _buildOptionsForSlot(l10n, slot, bundle, ownership);
            final currentThemeId = workingSelection[slot.assetId] ?? bundle.defaultThemeId;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _slotLabel(l10n, slot),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (slot.descriptionKey != null) ...[
                      4.0.spaceY,
                      Text(
                        slot.descriptionKey!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    12.0.spaceY,
                    if (options.isEmpty)
                      Text(
                        l10n.skinLoadoutEmptySlot,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: options
                              .map(
                                (option) => _ThemeOptionTile(
                                  option: option,
                                  isSelected: option.themeId == currentThemeId,
                                  onTap: () => onSelectTheme(
                                    slot.assetId,
                                    option.themeId,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ThemeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageProvider = option.previewUrl != null ? CachedNetworkImageProvider(option.previewUrl!) : null;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
                child: imageProvider == null ? const Icon(Icons.image_not_supported_outlined) : null,
              ),
              12.0.spaceY,
              Text(
                option.themeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (option.variantName != null)
                Text(
                  option.variantName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (option.isDefault)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      option.defaultLabel ?? 'Default',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinPreviewPane extends StatelessWidget {
  const _SkinPreviewPane({
    required this.l10n,
    required this.resolver,
    required this.cards,
  });

  final AppLocalizations l10n;
  final _ThemePreviewResolver resolver;
  final List<CardModel> cards;

  @override
  Widget build(BuildContext context) {
    final background = resolver.imageFor('background');
    final decoration = background != null
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            image: DecorationImage(
              image: background,
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.08),
                BlendMode.srcOver,
              ),
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: decoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.skinLoadoutPreviewTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            4.0.spaceY,
            Text(
              l10n.skinLoadoutPreviewDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            16.0.spaceY,
            Text(
              l10n.skinSlotBoardSurface,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            8.0.spaceY,
            _PreviewBoard(resolver: resolver),
            24.0.spaceY,
            Text(
              l10n.skinLoadoutAllCardsLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            8.0.spaceY,
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return SizedBox(
                    width: 160,
                    child: CardWidget(
                      card: card,
                      localizedName: _cardTitle(l10n, card.name),
                      color: card.color,
                      selectable: false,
                      canTap: false,
                      isReserve: true,
                      textureOverride: resolver.imageFor('card${card.name}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBoard extends StatelessWidget {
  const _PreviewBoard({required this.resolver});

  final _ThemePreviewResolver resolver;

  @override
  Widget build(BuildContext context) {
    final boardImage = resolver.imageFor('board');
    final cellLight = resolver.imageFor('board0');
    final cellDark = resolver.imageFor('board1');
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black,
          image: boardImage != null ? DecorationImage(image: boardImage, fit: BoxFit.cover) : null,
        ),
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / 5;
            return Stack(
              children: [
                GridView.builder(
                  itemCount: 25,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                  ),
                  itemBuilder: (context, index) {
                    final r = index ~/ 5;
                    final c = index % 5;
                    final isDark = (r + c) % 2 == 0;
                    final image = isDark ? cellDark : cellLight;
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.25),
                        image: image != null
                            ? DecorationImage(
                                image: image,
                                fit: BoxFit.cover,
                                opacity: 0.65,
                              )
                            : null,
                      ),
                    );
                  },
                ),
                ..._piecePlacements.map((piece) {
                  final image = resolver.imageFor(piece.assetId);
                  return Positioned(
                    left: piece.column * cellSize + cellSize * 0.1,
                    top: piece.row * cellSize + cellSize * 0.1,
                    width: cellSize * 0.8,
                    height: cellSize * 0.8,
                    child: image == null
                        ? Container(
                            decoration: BoxDecoration(
                              color: piece.isRed ? Colors.redAccent : Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Image(image: image),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum SkinSlotCategory { pieces, cards, boards, backgrounds }

class _SkinSlotDefinition {
  const _SkinSlotDefinition({
    required this.assetId,
    required this.category,
    this.descriptionKey,
  });

  final String assetId;
  final SkinSlotCategory category;
  final String? descriptionKey;
}

class _ThemeOption {
  const _ThemeOption({
    required this.themeId,
    required this.themeName,
    this.variantName,
    this.previewUrl,
    this.isDefault = false,
    this.defaultLabel,
  });

  final String themeId;
  final String themeName;
  final String? variantName;
  final String? previewUrl;
  final bool isDefault;
  final String? defaultLabel;
}

class _ThemeBundle {
  const _ThemeBundle({required this.themes, required this.defaultThemeId});

  final List<ThemeModel> themes;
  final String defaultThemeId;

  Map<String, ThemeModel> get byId => {for (final theme in themes) theme.id: theme};
}

class _ThemePreviewResolver {
  _ThemePreviewResolver(this.bundle, this.selection);

  final _ThemeBundle bundle;
  final Map<String, String> selection;

  ImageProvider<Object>? imageFor(String assetId) {
    final url = urlFor(assetId);
    if (url == null || url.isEmpty) {
      return null;
    }
    return CachedNetworkImageProvider(url);
  }

  String? urlFor(String assetId) {
    final themePreference = selection[assetId] ?? bundle.defaultThemeId;
    return _assetUrlFromTheme(themePreference, assetId) ?? _assetUrlFromTheme(bundle.defaultThemeId, assetId);
  }

  String? _assetUrlFromTheme(String themeId, String assetId) {
    final theme = bundle.byId[themeId];
    if (theme == null) {
      return null;
    }
    for (final candidate in _candidateKeys(assetId)) {
      final url = theme.assets[candidate];
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }
}

class _PiecePlacement {
  const _PiecePlacement(
    this.assetId,
    this.row,
    this.column, {
    required this.isRed,
  });

  final String assetId;
  final double row;
  final double column;
  final bool isRed;
}

const List<_PiecePlacement> _piecePlacements = <_PiecePlacement>[
  _PiecePlacement('r0', 0, 0, isRed: true),
  _PiecePlacement('r1', 0, 1, isRed: true),
  _PiecePlacement('master_red', 0, 2, isRed: true),
  _PiecePlacement('r2', 0, 3, isRed: true),
  _PiecePlacement('r3', 0, 4, isRed: true),
  _PiecePlacement('b0', 4, 0, isRed: false),
  _PiecePlacement('b1', 4, 1, isRed: false),
  _PiecePlacement('master_blue', 4, 2, isRed: false),
  _PiecePlacement('b2', 4, 3, isRed: false),
  _PiecePlacement('b3', 4, 4, isRed: false),
];

List<_ThemeOption> _buildOptionsForSlot(
  AppLocalizations l10n,
  _SkinSlotDefinition slot,
  _ThemeBundle bundle,
  ThemeOwnership ownership,
) {
  final options = <_ThemeOption>[];
  for (final theme in bundle.themes) {
    if (!_themeSupportsAsset(theme, slot.assetId)) {
      continue;
    }
    final isDefault = theme.id == bundle.defaultThemeId;
    final ownsAsset = isDefault || _ownsAsset(ownership, theme.id, slot.assetId);
    if (!ownsAsset) {
      continue;
    }
    options.add(
      _ThemeOption(
        themeId: theme.id,
        themeName: theme.name,
        variantName: _variantNameFor(theme, slot.assetId),
        previewUrl: _assetUrlFromTheme(theme, slot.assetId),
        isDefault: isDefault,
        defaultLabel: isDefault ? l10n.skinLoadoutDefaultTag : null,
      ),
    );
  }
  options.sort((a, b) {
    if (a.isDefault && !b.isDefault) return -1;
    if (b.isDefault && !a.isDefault) return 1;
    return a.themeName.toLowerCase().compareTo(b.themeName.toLowerCase());
  });
  return options;
}

bool _themeSupportsAsset(ThemeModel theme, String assetId) {
  for (final candidate in _candidateKeys(assetId)) {
    final url = theme.assets[candidate];
    if (url != null && url.isNotEmpty) {
      return true;
    }
  }
  return false;
}

String? _assetUrlFromTheme(ThemeModel theme, String assetId) {
  for (final candidate in _candidateKeys(assetId)) {
    final url = theme.assets[candidate];
    if (url != null && url.isNotEmpty) {
      return url;
    }
  }
  return null;
}

bool _ownsAsset(ThemeOwnership ownership, String themeId, String assetId) {
  final ownedAssets = ownership.assetsForTheme(themeId);
  if (ownedAssets.isEmpty) {
    return false;
  }
  for (final candidate in _candidateKeys(assetId)) {
    if (ownedAssets.contains(candidate)) {
      return true;
    }
  }
  return false;
}

String? _variantNameFor(ThemeModel theme, String assetId) {
  for (final variant in theme.values.values) {
    for (final candidate in _candidateKeys(assetId)) {
      if (variant.assets.contains(candidate)) {
        return variant.name;
      }
    }
  }
  return null;
}

Iterable<String> _candidateKeys(String assetId) {
  final keys = <String>{assetId};
  if (_isPieceAsset(assetId)) {
    keys.add('pieces');
  }
  if (assetId.startsWith('card')) {
    keys.add('cards');
  }
  if (assetId.startsWith('board')) {
    keys.add('board');
  }
  if (assetId == 'background') {
    keys.add('background');
  }
  keys.add('default');
  return keys;
}

bool _isPieceAsset(String assetId) {
  if (assetId.startsWith('master_')) {
    return true;
  }
  if (assetId.isEmpty) {
    return false;
  }
  final prefix = assetId[0];
  if (prefix != 'b' && prefix != 'r') {
    return false;
  }
  return assetId.substring(1).codeUnits.every((unit) => unit >= 48 && unit <= 57);
}

String _categoryLabel(AppLocalizations l10n, SkinSlotCategory category) {
  switch (category) {
    case SkinSlotCategory.pieces:
      return l10n.skinLoadoutCategoryPieces;
    case SkinSlotCategory.cards:
      return l10n.skinLoadoutCategoryCards;
    case SkinSlotCategory.boards:
      return l10n.skinLoadoutCategoryBoards;
    case SkinSlotCategory.backgrounds:
      return l10n.skinLoadoutCategoryBackgrounds;
  }
}

String _slotLabel(AppLocalizations l10n, _SkinSlotDefinition slot) {
  switch (slot.assetId) {
    case 'master_blue':
      return l10n.skinSlotBlueMaster;
    case 'master_red':
      return l10n.skinSlotRedMaster;
    case 'b0':
      return l10n.skinSlotBlueStudent1;
    case 'b1':
      return l10n.skinSlotBlueStudent2;
    case 'b2':
      return l10n.skinSlotBlueStudent3;
    case 'b3':
      return l10n.skinSlotBlueStudent4;
    case 'r0':
      return l10n.skinSlotRedStudent1;
    case 'r1':
      return l10n.skinSlotRedStudent2;
    case 'r2':
      return l10n.skinSlotRedStudent3;
    case 'r3':
      return l10n.skinSlotRedStudent4;
    case 'background':
      return l10n.skinSlotBackground;
    case 'board':
      return l10n.skinSlotBoardSurface;
    case 'board0':
      return l10n.skinSlotBoardLight;
    case 'board1':
      return l10n.skinSlotBoardDark;
    default:
      if (slot.assetId.startsWith('card')) {
        final name = slot.assetId.substring(4);
        final cardName = _cardTitle(l10n, name);
        return cardName;
      }
      return slot.assetId;
  }
}

String _cardTitle(AppLocalizations l10n, String cardName) {
  switch (cardName) {
    case 'Tiger':
      return l10n.cardTiger;
    case 'Dragon':
      return l10n.cardDragon;
    case 'Frog':
      return l10n.cardFrog;
    case 'Rabbit':
      return l10n.cardRabbit;
    case 'Crab':
      return l10n.cardCrab;
    case 'Elephant':
      return l10n.cardElephant;
    case 'Goose':
      return l10n.cardGoose;
    case 'Rooster':
      return l10n.cardRooster;
    case 'Monkey':
      return l10n.cardMonkey;
    case 'Mantis':
      return l10n.cardMantis;
    case 'Horse':
      return l10n.cardHorse;
    case 'Ox':
      return l10n.cardOx;
    case 'Crane':
      return l10n.cardCrane;
    case 'Boar':
      return l10n.cardBoar;
    case 'Eel':
      return l10n.cardEel;
    case 'Cobra':
      return l10n.cardCobra;
    default:
      return cardName;
  }
}

const List<_SkinSlotDefinition> _skinSlots = <_SkinSlotDefinition>[
  _SkinSlotDefinition(
    assetId: 'master_blue',
    category: SkinSlotCategory.pieces,
  ),
  _SkinSlotDefinition(assetId: 'b0', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'b1', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'b2', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'b3', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'master_red', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'r0', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'r1', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'r2', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'r3', category: SkinSlotCategory.pieces),
  _SkinSlotDefinition(assetId: 'cardTiger', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardDragon', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardFrog', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardRabbit', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardCrab', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(
    assetId: 'cardElephant',
    category: SkinSlotCategory.cards,
  ),
  _SkinSlotDefinition(assetId: 'cardGoose', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardRooster', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardMonkey', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardMantis', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardHorse', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardOx', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardCrane', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardBoar', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardEel', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(assetId: 'cardCobra', category: SkinSlotCategory.cards),
  _SkinSlotDefinition(
    assetId: 'background',
    category: SkinSlotCategory.backgrounds,
  ),
  _SkinSlotDefinition(assetId: 'board', category: SkinSlotCategory.boards),
  _SkinSlotDefinition(assetId: 'board0', category: SkinSlotCategory.boards),
  _SkinSlotDefinition(assetId: 'board1', category: SkinSlotCategory.boards),
];

final Set<String> _slotAssetIds = _skinSlots.map((slot) => slot.assetId).toSet();

List<CardModel> _buildReferenceCards() {
  return <CardModel>[
    CardModel('Tiger', [Point(-1, 0), Point(2, 0)], Colors.orange),
    CardModel(
      'Dragon',
      [Point(1, 2), Point(1, -2), Point(-1, 1), Point(-1, -1)],
      Colors.teal,
    ),
    CardModel('Frog', [Point(0, 2), Point(1, 1), Point(-1, -1)], Colors.cyan),
    CardModel(
      'Rabbit',
      [Point(-1, 1), Point(1, -1), Point(0, -2)],
      Colors.pinkAccent,
    ),
    CardModel(
      'Crab',
      [Point(0, -2), Point(0, 2), Point(1, 0)],
      Colors.blueGrey,
    ),
    CardModel(
      'Elephant',
      [Point(0, -1), Point(0, 1), Point(1, -1), Point(1, 1)],
      Colors.purple,
    ),
    CardModel(
      'Goose',
      [Point(0, -1), Point(0, 1), Point(-1, -1), Point(1, 1)],
      Colors.yellow,
    ),
    CardModel(
      'Rooster',
      [Point(0, -1), Point(0, 1), Point(-1, 1), Point(1, -1)],
      Colors.deepOrangeAccent,
    ),
    CardModel(
      'Monkey',
      [Point(-1, -1), Point(-1, 1), Point(1, -1), Point(1, 1)],
      Colors.brown,
    ),
    CardModel(
      'Mantis',
      [Point(1, 1), Point(1, -1), Point(-1, 0)],
      Colors.green,
    ),
    CardModel(
      'Horse',
      [Point(-1, 0), Point(1, 0), Point(0, 1)],
      Colors.deepPurpleAccent,
    ),
    CardModel(
      'Ox',
      [Point(-1, 0), Point(1, 0), Point(0, -1)],
      Colors.lightBlueAccent,
    ),
    CardModel(
      'Crane',
      [Point(1, 0), Point(-1, 1), Point(-1, -1)],
      Colors.lightGreen,
    ),
    CardModel(
      'Boar',
      [Point(0, -1), Point(0, 1), Point(1, 0)],
      Colors.redAccent,
    ),
    CardModel('Eel', [Point(1, 1), Point(-1, 1), Point(0, -1)], Colors.indigo),
    CardModel(
      'Cobra',
      [Point(-1, -1), Point(1, -1), Point(0, 1)],
      Colors.amber,
    ),
  ];
}
