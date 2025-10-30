class ThemeModel {
  final String id;
  final String name;
  final int version;
  final Map<String, String> assets;

  ThemeModel({required this.id, required this.name, required this.version, required this.assets});

  factory ThemeModel.fromMap(Map<String, dynamic> data, String id) {
    return ThemeModel(
      id: id,
      name: data['name'] ?? id,
      version: data['version'] ?? 0,
      assets: Map<String, String>.from(data['assets'] ?? {}),
    );
  }
}
