import 'dart:async';

import 'package:flutter/material.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Difficulty'),
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
              text: 'Easy',
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
              text: 'Medium',
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
              text: 'Hard',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Matchmaking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Waiting for an opponent...'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Onitama',
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 20),
            Text('The Game of the Masters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 60),
            StyledButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OnitamaHome(gameMode: GameMode.pvp, isHost: true)));
              },
              text: 'Local Multiplayer',
              icon: Icons.people,
            ),
            const SizedBox(height: 20),
            StyledButton(onPressed: () => _showDifficultyDialog(context), text: 'Player vs AI', icon: Icons.computer),
            const SizedBox(height: 20),
            StyledButton(onPressed: _findOrCreateGame, text: 'Online Multiplayer', icon: Icons.public),
            const SizedBox(height: 20),
            ExpansionTile(
              title: const Text('Private Game'),
              children: [
                const SizedBox(height: 10),
                StyledButton(onPressed: _createGame, text: 'Create Online Game', icon: Icons.add),
                const SizedBox(height: 20),
                TextField(
                  controller: _gameIdController,
                  decoration: const InputDecoration(labelText: 'Game ID', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                StyledButton(onPressed: _joinGame, text: 'Join Online Game', icon: Icons.login),
                const SizedBox(height: 10),
              ],
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HowToPlayScreen()));
              },
              label: Text('How to Play'),
              icon: Icon(Icons.rule),
            ),
          ],
        ),
      ),
    );
  }
}
