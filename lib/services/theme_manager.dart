import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../models/theme_model.dart';
import 'theme_service.dart';

class ThemeManager {
  static Map<String, ThemeModel> get themes => _themes;
  static final Map<String, ThemeModel> _themes = {};
  static final Map<String, CachedNetworkImageProvider> _imageCache = {};
  static final ThemeService _service = ThemeService();

  /// Carrega todos os temas disponíveis do Firestore
  static Future<void> loadAllThemes() async {
    final themes = await _service.fetchAvailableThemes();
    _themes.clear();
    for (final theme in themes) {
      _themes[theme.id] = theme;
    }
  }

  /// Precarrega todas as imagens de todos os temas
  static Future<void> preloadAllThemeImages(BuildContext context, {Function(int done, int total)? onProgress}) async {
    await loadAllThemes();
    final entries = <MapEntry<String, String>>[];
    for (final theme in _themes.values) {
      for (final entry in theme.assets.entries) {
        entries.add(MapEntry('${theme.id}-${entry.key}', entry.value));
      }
    }
    final total = entries.length;
    var done = 0;
    for (final entry in entries) {
      try {
        final img = CachedNetworkImageProvider(entry.value);
        _imageCache[entry.key] = img;
        await precacheImage(img, context);
      } catch (e) {
        debugPrint('Failed to precache ${entry.value}: $e');
      }
      done++;
      if (onProgress != null) onProgress(done, total);
    }
  }

  /// Retorna a URL da imagem para uma chave composta (ex: 'default-background')
  static String? assetUrl(String themeKey) {
    final parts = themeKey.split('-');
    if (parts.length != 2) return null;
    final theme = _themes[parts[0]];
    return theme?.assets[parts[1]];
  }

  /// Retorna o CachedNetworkImageProvider para uma chave composta
  static CachedNetworkImageProvider? cachedImage(String themeKey) {
    return _imageCache[themeKey];
  }
}
