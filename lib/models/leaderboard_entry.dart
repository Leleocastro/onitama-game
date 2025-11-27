import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.rating,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.tier,
    this.country,
    this.season,
    this.rank,
    this.photoUrl,
  });

  final String userId;
  final String username;
  final int rating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final String tier;
  final String? country;
  final String? season;
  final int? rank;
  final String? photoUrl;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  LeaderboardEntry copyWith({
    int? rank,
    String? photoUrl,
  }) {
    return LeaderboardEntry(
      userId: userId,
      username: username,
      rating: rating,
      gamesPlayed: gamesPlayed,
      wins: wins,
      losses: losses,
      tier: tier,
      country: country,
      season: season,
      rank: rank ?? this.rank,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  static LeaderboardEntry fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return LeaderboardEntry(
      userId: snapshot.id,
      username: (data['username'] as String?) ?? 'Jogador',
      rating: (data['rating'] as num?)?.round() ?? 1200,
      gamesPlayed: (data['gamesPlayed'] as num?)?.round() ?? 0,
      wins: (data['wins'] as num?)?.round() ?? 0,
      losses: (data['losses'] as num?)?.round() ?? 0,
      tier: (data['tier'] as String?) ?? 'Bronze',
      country: data['country'] as String?,
      season: data['season'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
