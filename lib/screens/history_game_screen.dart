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
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final userId = FirebaseAuth.instance.currentUser?.uid;
              String resultText;
              if (userId != null && (game.winner == null)) {
                resultText = l10n.historyNA;
              } else if (userId != null && (game.players[game.winner?.name] == userId)) {
                resultText = l10n.historyWon;
              } else if (userId != null && (game.players.values.contains(userId))) {
                resultText = l10n.historyLost;
              } else {
                resultText = l10n.historyNA;
              }
              final date = game.createdAt.toDate();
              final formattedDate = MaterialLocalizations.of(context).formatShortDate(date);
              return ListTile(
                title: Text('${l10n.historyGameOn} $formattedDate'),
                subtitle: Text(resultText),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HistoricGameDetailScreen(moves: game.gameHistory),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
