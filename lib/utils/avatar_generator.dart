import 'package:flutter/material.dart';

/// Immutable data required to paint a generated avatar.
class AvatarToken {
  const AvatarToken({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.pattern,
  }) : assert(pattern.length == AvatarGenerator.gridSize * AvatarGenerator.gridSize, 'Unexpected pattern length');

  final Color backgroundColor;
  final Color foregroundColor;
  final List<bool> pattern;
}

/// Deterministically creates identicon-like avatars from usernames, similar to GitHub.
class AvatarGenerator {
  static const int gridSize = 5;

  static final Map<String, AvatarToken> _cache = <String, AvatarToken>{};

  const AvatarGenerator._();

  /// Returns a cached avatar token for the provided [username].
  static AvatarToken fromUsername(String username) {
    final normalized = username.trim().toLowerCase().isEmpty ? 'player' : username.trim().toLowerCase();
    return _cache.putIfAbsent(normalized, () => _generate(normalized));
  }

  static AvatarToken _generate(String normalized) {
    var hash = _fnv1a32(normalized);
    final safeHash = hash & 0x7fffffff;
    final background = _backgroundPalette[safeHash % _backgroundPalette.length];
    final foreground = _accentPalette[(safeHash >> 3) % _accentPalette.length];
    final pattern = List<bool>.filled(gridSize * gridSize, false);
    final mirrorColumns = (gridSize / 2).ceil();

    for (var row = 0; row < gridSize; row++) {
      for (var column = 0; column < mirrorColumns; column++) {
        hash = _mix(hash, row, column);
        final shouldPaint = (hash & 0x1) == 1;
        final leftIndex = row * gridSize + column;
        final rightIndex = row * gridSize + (gridSize - 1 - column);
        pattern[leftIndex] = shouldPaint;
        pattern[rightIndex] = shouldPaint;
      }
    }

    return AvatarToken(
      backgroundColor: background,
      foregroundColor: foreground,
      pattern: pattern,
    );
  }

  static int _mix(int baseHash, int row, int column) {
    var hash = baseHash ^ ((row + 1) * 0x45d9f3b) ^ ((column + 7) * 0x27d4eb2d);
    hash = (hash ^ (hash >> 16)) & 0xffffffff;
    hash = (hash ^ (hash >> 8)) & 0xffffffff;
    return hash;
  }

  static int _fnv1a32(String value) {
    const fnvPrime = 0x01000193;
    const fnvOffset = 0x811c9dc5;
    var hash = fnvOffset;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash;
  }

  static const List<Color> _backgroundPalette = <Color>[
    Color(0xFFF6F8FA),
    Color(0xFFEFF3F6),
    Color(0xFFFDF2F8),
    Color(0xFFF4F0FF),
    Color(0xFFEEFDF5),
    Color(0xFFECF7FF),
  ];

  static const List<Color> _accentPalette = <Color>[
    Color(0xFF4C72FF),
    Color(0xFF9B51E0),
    Color(0xFFDB4437),
    Color(0xFF0F9D58),
    Color(0xFF00AEEF),
    Color(0xFFF4B400),
    Color(0xFFFD7F20),
    Color(0xFF6D4C41),
  ];
}
