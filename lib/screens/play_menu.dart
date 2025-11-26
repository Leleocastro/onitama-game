import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_difficulty.dart';
import '../models/game_mode.dart';
import '../services/firestore_service.dart';
import '../utils/extensions.dart';
import '../widgets/input_text.dart';
import '../widgets/styled_button.dart';
import 'game_lobby_screen.dart';
import 'interstitial_ad_screen.dart';
import 'onitama_home.dart';

class PlayMenu extends StatefulWidget {
  const PlayMenu({
    required this.playerUid,
    super.key,
  });
  final String playerUid;

  @override
  State<PlayMenu> createState() => _PlayMenuState();
}

class _PlayMenuState extends State<PlayMenu> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _gameIdController = TextEditingController();

  StreamSubscription? _gameSubscription;
  Timer? _gameCreationTimer;
  String? _playerUid;

  @override
  void initState() {
    _playerUid = widget.playerUid;
    super.initState();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _gameCreationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            20.0.spaceY,
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Spacer(),
            Column(
              children: [
                // InkWell(
                //   onTap: () {},
                //   child: Text(
                //     'Start Game',
                //     style: TextStyle(
                //       fontFamily: 'SpellOfAsia',
                //       color: Colors.white,
                //       fontSize: 48,
                //     ),
                //   ),
                // ),
                StyledButton(
                  onPressed: _findOrCreateGame,
                  textStyle: TextStyle(
                    fontFamily: 'SpellOfAsia',
                    color: Colors.white,
                    fontSize: 32,
                  ),
                  text: 'Start',
                ),
                10.0.spaceY,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InterstitialAdScreen(
                              navigateTo: OnitamaHome(
                                gameMode: GameMode.pvp,
                                isHost: true,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: Image.asset(
                        'assets/icons/versus.png',
                        width: 32,
                        color: Colors.white,
                      ),
                    ),
                    8.0.spaceX,
                    IconButton(
                      onPressed: () => _showDifficultyDialog(context),
                      icon: Image.asset(
                        'assets/icons/robot.png',
                        width: 32,
                        color: Colors.white,
                      ),
                    ),
                    8.0.spaceX,
                    IconButton(
                      onPressed: () => _showMultiPrivateDialog(context),
                      icon: Image.asset(
                        'assets/icons/multi-private.png',
                        width: 28,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            40.0.spaceY,
          ],
        ),
      ),
    );
  }

  void _showMultiPrivateDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privateGame),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            10.0.spaceY,
            StyledButton(
              onPressed: _createGame,
              text: l10n.createOnlineGame,
              icon: Icons.add,
            ),
            20.0.spaceY,
            InputText(
              controller: _gameIdController,
              labelText: l10n.gameId,
            ),
            10.0.spaceY,
            StyledButton(
              onPressed: _joinGame,
              text: l10n.joinOnlineGame,
              icon: Icons.login,
            ),
            10.0.spaceY,
          ],
        ),
      ),
    );
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
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: GameMode.pvai,
                        aiDifficulty: AIDifficulty.easy,
                        isHost: true,
                      ),
                    ),
                  ),
                );
              },
              text: l10n.easy,
            ),
            const SizedBox(height: 10),
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: GameMode.pvai,
                        aiDifficulty: AIDifficulty.medium,
                        isHost: true,
                      ),
                    ),
                  ),
                );
              },
              text: l10n.medium,
            ),
            const SizedBox(height: 10),
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: GameMode.pvai,
                        aiDifficulty: AIDifficulty.hard,
                        isHost: true,
                      ),
                    ),
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
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _playerUid;
    if (currentUid == null) return;
    final gameId = await _firestoreService.createGame(currentUid);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: currentUid),
      ),
    );
  }

  Future<void> _joinGame() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _playerUid;
    if (currentUid == null) return;
    final gameId = _gameIdController.text.trim();
    if (gameId.isNotEmpty) {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      _firestoreService.joinGame(gameId, currentUid);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: currentUid),
        ),
      );
    }
  }

  Future<void> _findOrCreateGame() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _playerUid;
    if (currentUid == null) return;
    _showWaitingDialog();

    final result = await _firestoreService.findOrCreateGame(currentUid);
    final gameId = result['gameId'];
    final isHost = result['isHost'];
    final inProgress = result['inProgress'] ?? false;

    if (inProgress) {
      if (!mounted) return;
      Navigator.pop(context); // Close waiting dialog
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnitamaHome(
            gameMode: GameMode.online,
            gameId: gameId,
            playerUid: currentUid,
            isHost: isHost,
          ),
        ),
      );
      return;
    }

    if (isHost) {
      _gameCreationTimer = Timer(const Duration(seconds: 20), () {
        _gameSubscription?.cancel();
        _firestoreService.convertToPvAI(gameId);
        if (!mounted) return;
        Navigator.pop(context); // Close waiting dialog
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnitamaHome(
              gameMode: GameMode.online,
              gameId: gameId,
              playerUid: currentUid,
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
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OnitamaHome(
                gameMode: GameMode.online,
                gameId: gameId,
                playerUid: currentUid,
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
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnitamaHome(
            gameMode: GameMode.online,
            gameId: gameId,
            playerUid: currentUid,
            isHost: false,
          ),
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
}
