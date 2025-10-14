import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../services/firestore_service.dart';
import 'onitama_home.dart';

class GameLobbyScreen extends StatefulWidget {
  final String gameId;
  final String playerUid;

  const GameLobbyScreen({required this.gameId, required this.playerUid, super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Lobby')),
      body: StreamBuilder<FirestoreGame>(
        stream: _firestoreService.streamGame(widget.gameId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = snapshot.data!;

          // Check if both players have joined
          if (game.players['red'] != null && game.players['blue'] != null) {
            // Navigate to game screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OnitamaHome(
                    gameMode: GameMode.online,
                    gameId: widget.gameId,
                    playerUid: widget.playerUid,
                    isHost: game.players['blue'] == widget.playerUid,
                  ),
                ),
              );
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Waiting for opponent...'),
                const SizedBox(height: 20),
                TextButton(
                  child: Text('Game ID: ${widget.gameId}'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.gameId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Game ID copied to clipboard')));
                  },
                ),
                const SizedBox(height: 20),
                Text('Players: ${game.players.length}/2'),
              ],
            ),
          );
        },
      ),
    );
  }
}
