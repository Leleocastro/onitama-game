import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/firestore_game.dart';
import '../services/firestore_service.dart';
import 'historic_game_detail_screen.dart';

class HistoryGameScreen extends StatefulWidget {
  const HistoryGameScreen({super.key});

  @override
  State<HistoryGameScreen> createState() => _HistoryGameScreenState();
}

class _HistoryGameScreenState extends State<HistoryGameScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<FirestoreGame>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = _firestoreService.getFinishedGames();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle, style: TextStyle(fontFamily: 'SpellOfAsia')),
      ),
      body: FutureBuilder<List<FirestoreGame>>(
        future: _gamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.historyErrorLoading));
          }
          final games = snapshot.data!;
          if (games.isEmpty) {
            return Center(child: Text(l10n.historyNoFinished));
          }
          final grouped = _groupGamesByDay(games);
          final userId = FirebaseAuth.instance.currentUser?.uid;
          final materialLocalization = MaterialLocalizations.of(context);
          final colorScheme = Theme.of(context).colorScheme;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final group = grouped[index];
              final dateLabel = materialLocalization.formatFullDate(group.date);
              return Padding(
                padding: EdgeInsets.only(bottom: index == grouped.length - 1 ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ...group.games.map((game) {
                      final result = _resolveGameResult(game, userId);
                      final iconData = _iconForResult(result);
                      final color = _colorForResult(result, colorScheme);
                      final label = _labelForResult(result, l10n);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(iconData, color: color),
                          title: Text(
                            label,
                            style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => HistoricGameDetailScreen(moves: game.gameHistory),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_GamesByDay> _groupGamesByDay(List<FirestoreGame> games) {
    final map = <DateTime, List<FirestoreGame>>{};
    for (final game in games) {
      final createdAt = game.createdAt.toDate();
      final key = DateTime(createdAt.year, createdAt.month, createdAt.day);
      map.putIfAbsent(key, () => []).add(game);
    }
    final entries = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    return entries.map((entry) => _GamesByDay(date: entry.key, games: entry.value)).toList();
  }

  _GameResult _resolveGameResult(FirestoreGame game, String? userId) {
    final normalizedStatus = game.status.toLowerCase();
    final isCanceled = normalizedStatus.contains('cancel');
    if (isCanceled || game.winner == null || userId == null) {
      return _GameResult.canceled;
    }
    final winnerUid = game.players[game.winner!.name];
    if (winnerUid == userId) {
      return _GameResult.win;
    }
    if (game.players.values.contains(userId)) {
      return _GameResult.loss;
    }
    return _GameResult.canceled;
  }

  IconData _iconForResult(_GameResult result) {
    switch (result) {
      case _GameResult.win:
        return Icons.emoji_events;
      case _GameResult.loss:
        return Icons.mood_bad;
      case _GameResult.canceled:
        return Icons.close;
    }
  }

  Color _colorForResult(_GameResult result, ColorScheme scheme) {
    switch (result) {
      case _GameResult.win:
        return Colors.green;
      case _GameResult.loss:
        return scheme.error;
      case _GameResult.canceled:
        return Colors.grey;
    }
  }

  String _labelForResult(_GameResult result, AppLocalizations l10n) {
    switch (result) {
      case _GameResult.win:
        return l10n.historyWon;
      case _GameResult.loss:
        return l10n.historyLost;
      case _GameResult.canceled:
        return l10n.historyCanceled;
    }
  }
}

class _GamesByDay {
  const _GamesByDay({required this.date, required this.games});

  final DateTime date;
  final List<FirestoreGame> games;
}

enum _GameResult { win, loss, canceled }
