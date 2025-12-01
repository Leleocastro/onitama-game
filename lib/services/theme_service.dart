import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/theme_model.dart';

class ThemeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  Future<ThemeModel?> fetchTheme(String themeId) async {
    final doc = await _db.collection('themes').doc(themeId).get();
    if (!doc.exists) return null;
    return ThemeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<List<ThemeModel>> fetchAvailableThemes() async {
    final q = await _db.collection('themes').where('enabled', isEqualTo: true).get();
    return q.docs.map((d) => ThemeModel.fromMap(d.data(), d.id)).toList();
  }

  Future<String?> fetchCurrentThemeId() async {
    try {
      final doc = await _db.collection('settings').doc('theme').get();
      if (!doc.exists) return null;
      final data = doc.data();
      final value = data?['current'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } catch (_) {
      // Intentionally swallow errors here; caller can fall back to default theme
    }
    return null;
  }
}
