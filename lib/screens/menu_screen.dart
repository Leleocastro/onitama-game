import 'package:flutter/material.dart';
import '../models/ai_difficulty.dart';
import '../models/game_mode.dart';
import './onitama_home.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
                    builder: (context) => const OnitamaHome(
                      gameMode: GameMode.pvai,
                      aiDifficulty: AIDifficulty.easy,
                    ),
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
                    builder: (context) => const OnitamaHome(
                      gameMode: GameMode.pvai,
                      aiDifficulty: AIDifficulty.medium,
                    ),
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
                    builder: (context) => const OnitamaHome(
                      gameMode: GameMode.pvai,
                      aiDifficulty: AIDifficulty.hard,
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onitama'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const OnitamaHome(gameMode: GameMode.pvp)),
                );
              },
              child: const Text('Local Multiplayer'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showDifficultyDialog(context),
              child: const Text('Player vs AI'),
            ),
          ],
        ),
      ),
    );
  }
}
