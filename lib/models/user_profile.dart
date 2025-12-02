import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.photoUrl,
    this.theme = const <String, String>{},
    this.goldBalance = 0,
  });

  final String id;
  final String username;
  final String? photoUrl;
  final Map<String, String> theme;
  final int goldBalance;

  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final themeData = data['theme'];
    final theme = <String, String>{};
    if (themeData is Map<String, dynamic>) {
      for (final entry in themeData.entries) {
        final value = entry.value;
        if (value is String && value.isNotEmpty) {
          theme[entry.key] = value;
        }
      }
    }
    return UserProfile(
      id: snapshot.id,
      username: (data['username'] as String?) ?? 'player',
      photoUrl: data['photoUrl'] as String?,
      theme: theme,
      goldBalance: (data['goldBalance'] as num?)?.round() ?? 0,
    );
  }
}
