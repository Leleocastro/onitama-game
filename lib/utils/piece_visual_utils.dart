import 'package:flutter/material.dart';

/// Color filter applied to red pieces when they share the same texture as blue pieces.
const ColorFilter redPieceDesaturationFilter = ColorFilter.matrix(<double>[
  0.65,
  0.175,
  0.175,
  0,
  0,
  0.175,
  0.65,
  0.175,
  0,
  0,
  0.175,
  0.175,
  0.65,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

/// Returns the counterpart asset id for a blue/red pair (e.g. r0 -> b0).
String? pairedPieceAssetId(String assetId) {
  if (assetId == 'master_red') return 'master_blue';
  if (assetId == 'master_blue') return 'master_red';
  if (assetId.length < 2) return null;
  final prefix = assetId[0];
  final suffix = assetId.substring(1);
  if (!_isNumeric(suffix)) return null;
  if (prefix == 'r') return 'b$suffix';
  if (prefix == 'b') return 'r$suffix';
  return null;
}

bool _isNumeric(String value) {
  if (value.isEmpty) return false;
  return int.tryParse(value) != null;
}
