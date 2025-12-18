import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();
  static const String _collection = 'settings';
  static const String _document = 'configs';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int? _cachedTimerMillis;

  int? get cachedTimerMillis => _cachedTimerMillis;

  Future<int?> fetchTimerMillis() async {
    if (_cachedTimerMillis != null) {
      return _cachedTimerMillis;
    }
    final doc = await _db.collection(_collection).doc(_document).get();
    if (!doc.exists) {
      return null;
    }
    final timerMinutes = (doc.data()?['timer'] as num?)?.toInt();
    if (timerMinutes == null || timerMinutes <= 0) {
      return null;
    }
    _cachedTimerMillis = timerMinutes * 60 * 1000;
    return _cachedTimerMillis;
  }

  void setCachedTimer(int? millis) {
    _cachedTimerMillis = millis;
  }
}
