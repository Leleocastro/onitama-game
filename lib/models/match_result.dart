class MatchResult {
  MatchResult({
    required this.gameId,
    required this.winnerColor,
    required this.participants,
    required this.processedAt,
    this.alreadyProcessed = false,
    this.aiOpponent,
    this.gameMode,
  });

  final String gameId;
  final String winnerColor;
  final List<MatchParticipantResult> participants;
  final DateTime processedAt;
  final bool alreadyProcessed;
  final MatchAiOpponent? aiOpponent;
  final String? gameMode;

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>?;
    return MatchResult(
      gameId: json['gameId'] as String? ?? '',
      winnerColor: json['winner'] as String? ?? '',
      participants: participantsJson == null ? const [] : participantsJson.whereType<Map<String, dynamic>>().map(MatchParticipantResult.fromJson).toList(),
      processedAt: _parseDate(json['processedAt']),
      alreadyProcessed: json['alreadyProcessed'] as bool? ?? false,
      aiOpponent: json['aiOpponent'] is Map<String, dynamic> ? MatchAiOpponent.fromJson(json['aiOpponent'] as Map<String, dynamic>) : null,
      gameMode: json['gameMode'] as String?,
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
  }
}

class MatchParticipantResult {
  MatchParticipantResult({
    required this.userId,
    required this.username,
    required this.color,
    required this.score,
    required this.expectedScore,
    required this.previousRating,
    required this.newRating,
    required this.ratingDelta,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.kFactor,
    required this.tier,
    required this.season,
    this.decay,
    this.goldReward = 0,
    this.goldBalance,
  });

  final String userId;
  final String? username;
  final String color;
  final int score;
  final double expectedScore;
  final int previousRating;
  final int newRating;
  final int ratingDelta;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int kFactor;
  final String tier;
  final String season;
  final RatingDecay? decay;
  final int goldReward;
  final int? goldBalance;

  bool get gainedRating => ratingDelta > 0;
  bool get lostRating => ratingDelta < 0;
  bool get earnedGold => goldReward > 0;

  factory MatchParticipantResult.fromJson(Map<String, dynamic> json) {
    final goldBalanceValue = json['goldBalance'];
    int? goldBalance;
    if (goldBalanceValue is num) {
      goldBalance = goldBalanceValue.round();
    }
    return MatchParticipantResult(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String?,
      color: json['color'] as String? ?? '',
      score: (json['score'] as num?)?.round() ?? 0,
      expectedScore: (json['expectedScore'] as num?)?.toDouble() ?? 0,
      previousRating: json['previousRating'] as int? ?? 0,
      newRating: json['newRating'] as int? ?? 0,
      ratingDelta: json['ratingDelta'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      kFactor: json['kFactor'] as int? ?? 0,
      tier: json['tier'] as String? ?? '',
      season: json['season'] as String? ?? '',
      decay: json['decay'] is Map<String, dynamic> ? RatingDecay.fromJson(json['decay'] as Map<String, dynamic>) : null,
      goldReward: (json['goldReward'] as num?)?.round() ?? 0,
      goldBalance: goldBalance,
    );
  }
}

class RatingDecay {
  RatingDecay({required this.weeks, required this.amount});

  final int weeks;
  final double amount;

  factory RatingDecay.fromJson(Map<String, dynamic> json) {
    return RatingDecay(
      weeks: (json['weeks'] as num?)?.round() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MatchAiOpponent {
  MatchAiOpponent({required this.difficulty, required this.rating});

  final String difficulty;
  final int rating;

  factory MatchAiOpponent.fromJson(Map<String, dynamic> json) {
    return MatchAiOpponent(
      difficulty: json['difficulty'] as String? ?? 'medium',
      rating: json['rating'] as int? ?? 0,
    );
  }
}
