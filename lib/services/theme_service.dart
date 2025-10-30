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
}
