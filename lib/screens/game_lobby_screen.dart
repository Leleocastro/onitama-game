import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
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
      appBar: AppBar(title: const Text('Lobby', style: TextStyle(fontFamily: 'SpellOfAsia'))),
      body: StreamBuilder<FirestoreGame>(
        stream: _firestoreService.streamGame(widget.gameId),
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context)!;
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
                Text(l10n.waitingForAnOpponent),
                const SizedBox(height: 20),
                TextButton(
                  child: Text(l10n.lobbyGameIdLabel(widget.gameId)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.gameId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.lobbyGameIdCopied)),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(l10n.lobbyPlayersCount(game.players.length)),
              ],
            ),
          );
        },
      ),
    );
  }
}
