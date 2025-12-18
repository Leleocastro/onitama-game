class ThemeOwnership {
  const ThemeOwnership._(this._themes);

  factory ThemeOwnership(Map<String, Set<String>> themes) {
    final normalized = <String, Set<String>>{};
    themes.forEach((key, value) {
      if (value.isNotEmpty) {
        normalized[key] = Set.unmodifiable(value);
      }
    });
    return ThemeOwnership._(Map.unmodifiable(normalized));
  }

  factory ThemeOwnership.empty() => const ThemeOwnership._(<String, Set<String>>{});

  final Map<String, Set<String>> _themes;

  Map<String, Set<String>> get themes => _themes;

  Set<String> assetsForTheme(String themeId) => _themes[themeId] ?? const <String>{};

  bool ownsAll(String themeId, Iterable<String> assetIds) {
    if (assetIds.isEmpty) return false;
    final owned = _themes[themeId];
    if (owned == null || owned.isEmpty) return false;
    for (final assetId in assetIds) {
      if (!owned.contains(assetId)) {
        return false;
      }
    }
    return true;
  }

  bool get isEmpty => _themes.isEmpty;
}
