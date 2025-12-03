import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/player.dart';
import '../models/theme_model.dart';
import 'theme_image_preload_worker.dart';
import 'theme_service.dart';

class ThemeManager {
  static Map<String, ThemeModel> get themes => _themes;
  static String get currentThemeId => _currentThemeId;

  static const String _fallbackThemeId = 'default';
  static final Map<String, ThemeModel> _themes = {};
  static final Map<String, ImageProvider<Object>> _imageCache = {};
  static final ThemeService _service = ThemeService();
  static String _currentThemeId = _fallbackThemeId;
  static final Map<PlayerColor, Map<String, String>> _playerThemeOverrides = {};

  /// Carrega todos os temas disponíveis do Firestore
  static Future<void> loadAllThemes() async {
    final remoteThemeId = await _service.fetchCurrentThemeId();
    if (remoteThemeId != null && remoteThemeId.isNotEmpty) {
      _currentThemeId = remoteThemeId;
    }

    final themes = await _service.fetchAvailableThemes();
    _themes.clear();
    for (final theme in themes) {
      _themes[theme.id] = theme;
    }

    if (_themes.isEmpty) return;
    if (!_themes.containsKey(_currentThemeId)) {
      _currentThemeId = _themes.keys.first;
    }
  }

  /// Precarrega todas as imagens de todos os temas
  static Future<void> preloadAllThemeImages(BuildContext context, {Function(int done, int total)? onProgress}) async {
    if (_themes.isEmpty) {
      await loadAllThemes();
    }
    final entries = <MapEntry<String, String>>[];
    for (final theme in _themes.values) {
      for (final entry in theme.assets.entries) {
        entries.add(MapEntry('${theme.id}-${entry.key}', entry.value));
      }
    }
    final total = entries.length;
    if (total == 0) {
      if (onProgress != null) onProgress(0, 0);
      return;
    }

    var done = 0;
    final worker = ThemeImagePreloadWorker();
    final cacheManager = DefaultCacheManager();
    final urlByKey = {for (final entry in entries) entry.key: entry.value};
    _imageCache
      ..clear()
      ..addEntries(
        entries.map(
          (entry) => MapEntry(entry.key, NetworkImage(entry.value)),
        ),
      );
    final entriesToDownload = <MapEntry<String, String>>[];
    for (final entry in entries) {
      final cached = await cacheManager.getFileFromCache(entry.value);
      if (cached == null) {
        entriesToDownload.add(entry);
        continue;
      }
      try {
        final bytes = await cached.file.readAsBytes();
        final image = MemoryImage(bytes);
        _imageCache[entry.key] = image;
        await precacheImage(image, context);
      } catch (error) {
        entriesToDownload.add(entry);
        continue;
      }
      done++;
      onProgress?.call(done, total);
    }

    if (entriesToDownload.isEmpty) return;

    await worker.download(
      entriesToDownload,
      onImage: (key, bytes) async {
        final image = MemoryImage(bytes);
        _imageCache[key] = image;
        await precacheImage(image, context);
        final url = urlByKey[key];
        if (url != null) {
          final ext = _extensionFromUrl(url) ?? 'img';
          unawaited(cacheManager.putFile(url, bytes, fileExtension: ext));
        }
        done++;
        onProgress?.call(done, total);
      },
      onError: (key, error) {
        done++;
        onProgress?.call(done, total);
        final url = urlByKey[key];
        debugPrint('Failed to download $key (${url ?? 'unknown url'}): $error');
      },
    );
  }

  static String? _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments;
    if (segments == null || segments.isEmpty) return null;
    final last = segments.last;
    final dotIndex = last.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == last.length - 1) return null;
    return last.substring(dotIndex + 1);
  }

  /// Retorna a URL da imagem para uma chave composta (ex: 'default-background')
  static String? assetUrl(String themeKey) {
    final parts = themeKey.split('-');
    if (parts.length != 2) return null;
    final theme = _themes[parts[0]];
    return theme?.assets[parts[1]];
  }

  /// Retorna o ImageProvider para uma chave composta
  static ImageProvider<Object>? cachedImage(String themeKey) {
    return _imageCache[themeKey];
  }

  /// Registra um mapa de overrides de tema por jogador
  static void setPlayerTheme(PlayerColor color, Map<String, String>? overrides) {
    if (overrides == null || overrides.isEmpty) {
      _playerThemeOverrides.remove(color);
      return;
    }
    _playerThemeOverrides[color] = Map<String, String>.from(overrides);
  }

  /// Remove todos os overrides de jogador ativos
  static void clearPlayerThemes() {
    _playerThemeOverrides.clear();
  }

  /// Retorna a chave completa (ex: '<tema>-background') para um asset
  static String themedKey(String assetId, {PlayerColor? owner}) {
    final themeId = _themeIdForAsset(assetId, owner: owner);
    return '$themeId-$assetId';
  }

  /// Atalho para recuperar uma imagem considerando overrides de jogador
  static ImageProvider<Object>? themedImage(String assetId, {PlayerColor? owner}) {
    return cachedImage(themedKey(assetId, owner: owner));
  }

  /// Recupera a URL do asset considerando overrides de jogador
  static String? themedAssetUrl(String assetId, {PlayerColor? owner}) {
    return assetUrl(themedKey(assetId, owner: owner));
  }

  static String _themeIdForAsset(String assetId, {PlayerColor? owner}) {
    final wantsRedOverride = owner == PlayerColor.red && _isRedExclusiveAsset(assetId);
    if (wantsRedOverride) {
      final redOverride = _themeIdFromOverrides(_playerThemeOverrides[PlayerColor.red], assetId);
      if (redOverride != null) return redOverride;
      return _currentThemeId;
    }

    final hostOverride = _themeIdFromOverrides(_playerThemeOverrides[PlayerColor.blue], assetId);
    if (hostOverride != null) return hostOverride;

    return _currentThemeId;
  }

  static String? _themeIdFromOverrides(Map<String, String>? overrides, String assetId) {
    if (overrides == null || overrides.isEmpty) return null;
    for (final key in _candidateKeys(assetId)) {
      final value = overrides[key];
      if (value != null && value.isNotEmpty && _themes.containsKey(value)) {
        return value;
      }
    }
    return null;
  }

  static Iterable<String> _candidateKeys(String assetId) {
    final keys = <String>{assetId};
    if (assetId.startsWith('card')) {
      keys.add('cards');
    }
    if (_isPieceAsset(assetId)) {
      keys.add('pieces');
    }
    if (assetId.startsWith('board')) {
      keys.add('board');
    }
    keys.add('default');
    return keys;
  }

  static bool _isPieceAsset(String assetId) {
    return assetId.startsWith('master_') || _isStudentAsset(assetId);
  }

  static bool _isStudentAsset(String assetId) {
    if (assetId.length < 2) return false;
    final prefix = assetId[0];
    if (prefix != 'r' && prefix != 'b') return false;
    return assetId.substring(1).codeUnits.every((unit) => unit >= 48 && unit <= 57);
  }

  static bool _isRedExclusiveAsset(String assetId) {
    return assetId.startsWith('card') || _isPieceAsset(assetId);
  }
}
