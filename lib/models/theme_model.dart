class ThemeModel {
  final String id;
  final String name;
  final String? description;
  final bool enabled;
  final int version;
  final Map<String, String> assets;
  final Map<String, ThemeVariantModel> values;

  ThemeModel({
    required this.id,
    required this.name,
    required this.version,
    required this.assets,
    this.description,
    this.enabled = false,
    Map<String, ThemeVariantModel>? values,
  }) : values = Map.unmodifiable(values ?? const <String, ThemeVariantModel>{});

  factory ThemeModel.fromMap(Map<String, dynamic> data, String id) {
    final values = <String, ThemeVariantModel>{};
    final rawValues = data['values'];
    if (rawValues is Map<String, dynamic>) {
      for (final entry in rawValues.entries) {
        final valueData = entry.value;
        if (valueData is Map<String, dynamic>) {
          final variant = ThemeVariantModel.fromMap(entry.key, valueData);
          if (variant != null) {
            values[variant.id] = variant;
          }
        }
      }
    }

    return ThemeModel(
      id: id,
      name: (data['name'] as String?) ?? id,
      description: data['description'] as String?,
      enabled: (data['enabled'] as bool?) ?? false,
      version: (data['version'] as num?)?.toInt() ?? 0,
      assets: Map<String, String>.from(data['assets'] ?? const <String, String>{}),
      values: values,
    );
  }
}

class ThemeVariantModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String type;
  final List<String> assets;
  final int value;
  final double discount;

  const ThemeVariantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.assets,
    required this.value,
    required this.discount,
  });

  static ThemeVariantModel? fromMap(String id, Map<String, dynamic> data) {
    final rawAssets = data['assets'];
    final assets = <String>[];
    if (rawAssets is Iterable) {
      for (final entry in rawAssets) {
        if (entry is String && entry.isNotEmpty) {
          assets.add(entry);
        }
      }
    }
    if (assets.isEmpty) {
      return null;
    }

    final value = (data['value'] as num?)?.round();
    if (value == null || value <= 0) {
      return null;
    }

    final rawDiscount = data['discount'];
    final discount = rawDiscount is num ? rawDiscount.toDouble().clamp(0.0, 0.95) : 0.0;

    return ThemeVariantModel(
      id: id,
      name: data['name'] as String? ?? id,
      description: data['description'] as String? ?? '',
      imageUrl: data['image'] as String? ?? '',
      type: (data['type'] as String? ?? 'all').toLowerCase(),
      assets: List.unmodifiable(assets),
      value: value,
      discount: discount,
    );
  }

  int get finalPrice {
    final effectiveDiscount = discount.clamp(0.0, 0.95);
    return (value * (1 - effectiveDiscount)).round();
  }

  bool get hasAssets => assets.isNotEmpty;
  bool get hasDiscount => discount > 0;
}
