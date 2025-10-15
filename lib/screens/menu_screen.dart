import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_difficulty.dart';
import '../models/game_mode.dart';
import '../services/firestore_service.dart';
import '../widgets/styled_button.dart';
import './game_lobby_screen.dart';
import './how_to_play_screen.dart';
import './onitama_home.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _gameIdController = TextEditingController();

  String? _playerUid;
  StreamSubscription? _gameSubscription;
  Timer? _gameCreationTimer;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _gameCreationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    _playerUid = await _firestoreService.signInAnonymously();
    setState(() {});
  }

  void _showDifficultyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectDifficulty),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnitamaHome(gameMode: GameMode.pvai, aiDifficulty: AIDifficulty.easy, isHost: true),
                  ),
                );
              },
              text: l10n.easy,
            ),
            const SizedBox(height: 10),
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnitamaHome(gameMode: GameMode.pvai, aiDifficulty: AIDifficulty.medium, isHost: true),
                  ),
                );
              },
              text: l10n.medium,
            ),
            const SizedBox(height: 10),
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnitamaHome(gameMode: GameMode.pvai, aiDifficulty: AIDifficulty.hard, isHost: true),
                  ),
                );
              },
              text: l10n.hard,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGame() async {
    if (_playerUid == null) return;
    final gameId = await _firestoreService.createGame(_playerUid!);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: _playerUid!),
      ),
    );
  }

  Future<void> _joinGame() async {
    if (_playerUid == null) return;
    final gameId = _gameIdController.text.trim();
    if (gameId.isNotEmpty) {
      if (!mounted) return;
      _firestoreService.joinGame(gameId, _playerUid!);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: _playerUid!),
        ),
      );
    }
  }

  Future<void> _findOrCreateGame() async {
    if (_playerUid == null) return;
    _showWaitingDialog();

    final result = await _firestoreService.findOrCreateGame(_playerUid!);
    final gameId = result['gameId'];
    final isHost = result['isHost'];

    if (isHost) {
      _gameCreationTimer = Timer(const Duration(seconds: 20), () {
        _gameSubscription?.cancel();
        _firestoreService.convertToPvAI(gameId);
        if (!mounted) return;
        Navigator.pop(context); // Close waiting dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnitamaHome(
              gameMode: GameMode.online,
              gameId: gameId,
              playerUid: _playerUid!,
              isHost: true,
              hasDelay: true,
            ),
          ),
        );
      });

      _gameSubscription = _firestoreService.streamGame(gameId).listen((game) {
        if (game.players.length > 1) {
          _gameCreationTimer?.cancel();
          if (!mounted) return;
          Navigator.pop(context); // Close waiting dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OnitamaHome(
                gameMode: GameMode.online,
                gameId: gameId,
                playerUid: _playerUid!,
                isHost: true,
              ),
            ),
          );
          _gameSubscription?.cancel();
        }
      });
    } else {
      if (!mounted) return;
      Navigator.pop(context); // Close waiting dialog
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnitamaHome(gameMode: GameMode.online, gameId: gameId, playerUid: _playerUid!, isHost: false),
        ),
      );
    }
  }

  void _showWaitingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.matchmaking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(l10n.waitingForAnOpponent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              l10n.onitama,
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 20),
            Text(l10n.gameOfTheMasters, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 60),
            StyledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OnitamaHome(gameMode: GameMode.pvp, isHost: true)));
              },
              text: l10n.localMultiplayer,
              icon: Icons.people,
            ),
            const SizedBox(height: 20),
            StyledButton(onPressed: () => _showDifficultyDialog(context), text: l10n.playerVsAi, icon: Icons.computer),
            const SizedBox(height: 20),
            StyledButton(onPressed: _findOrCreateGame, text: l10n.onlineMultiplayer, icon: Icons.public),
            const SizedBox(height: 20),
            ExpansionTile(
              title: Text(l10n.privateGame),
              children: [
                const SizedBox(height: 10),
                StyledButton(onPressed: _createGame, text: l10n.createOnlineGame, icon: Icons.add),
                const SizedBox(height: 20),
                TextField(
                  controller: _gameIdController,
                  decoration: InputDecoration(labelText: l10n.gameId, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                StyledButton(onPressed: _joinGame, text: l10n.joinOnlineGame, icon: Icons.login),
                const SizedBox(height: 10),
              ],
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HowToPlayScreen()));
              },
              label: Text(l10n.howToPlay),
              icon: const Icon(Icons.rule),
            ),
          ],
        ),
      ),
    );
  }
}
