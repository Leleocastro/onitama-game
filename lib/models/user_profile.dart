import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.photoUrl,
  });

  final String id;
  final String username;
  final String? photoUrl;

  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return UserProfile(
      id: snapshot.id,
      username: (data['username'] as String?) ?? 'player',
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
