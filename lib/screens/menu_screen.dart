import 'package:flutter/material.dart';
import 'package:onitama/services/firestore_service.dart';

import '../models/ai_difficulty.dart';
import '../models/game_mode.dart';
import './game_lobby_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeUser();
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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnitamaHome(gameMode: GameMode.pvai, aiDifficulty: AIDifficulty.easy),
                  ),
                );
              },
              child: const Text('Easy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnitamaHome(gameMode: GameMode.pvai, aiDifficulty: AIDifficulty.medium),
                  ),
                );
              },
              child: const Text('Medium'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnitamaHome(gameMode: GameMode.pvai, aiDifficulty: AIDifficulty.hard),
                  ),
                );
              },
              child: const Text('Hard'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGame() async {
    if (_playerUid == null) return;
    String gameId = await _firestoreService.createGame(_playerUid!);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: _playerUid!),
      ),
    );
  }

  Future<void> _joinGame() async {
    if (_playerUid == null) return;
    String gameId = _gameIdController.text.trim();
    if (gameId.isNotEmpty) {
      if (!mounted) return;
      _firestoreService.joinGame(gameId, _playerUid!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: _playerUid!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onitama')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OnitamaHome(gameMode: GameMode.pvp)));
              },
              child: const Text('Local Multiplayer'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => _showDifficultyDialog(context), child: const Text('Player vs AI')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _createGame, child: const Text('Create Online Game')),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _gameIdController,
                decoration: const InputDecoration(labelText: 'Game ID', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _joinGame, child: const Text('Join Online Game')),
          ],
        ),
      ),
    );
  }
}
