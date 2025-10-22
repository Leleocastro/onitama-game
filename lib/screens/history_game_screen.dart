import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
      ),
      body: FutureBuilder<List<FirestoreGame>>(
        future: _gamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading games.'));
          }
          final games = snapshot.data!;
          if (games.isEmpty) {
            return const Center(child: Text('No finished games found.'));
          }
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return ListTile(
                title: Text('Game on ${game.createdAt.toDate()}'),
                subtitle: Text('Winner: ${game.winner?.name ?? 'N/A'}'),
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
