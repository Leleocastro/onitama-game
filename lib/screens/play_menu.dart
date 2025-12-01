import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_difficulty.dart';
import '../models/game_mode.dart';
import '../services/firestore_service.dart';
import '../services/tutorial_service.dart';
import '../utils/extensions.dart';
import '../widgets/input_text.dart';
import '../widgets/styled_button.dart';
import '../widgets/tutorial_card.dart';
import 'game_lobby_screen.dart';
import 'interstitial_ad_screen.dart';
import 'login_screen.dart';
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
  final GlobalKey _startGameKey = GlobalKey();
  final GlobalKey _pvpKey = GlobalKey();
  final GlobalKey _aiKey = GlobalKey();
  final GlobalKey _privateKey = GlobalKey();
  bool _playMenuTutorialScheduled = false;

  @override
  void initState() {
    _playerUid = widget.playerUid;
    super.initState();
    Future.delayed(Duration(milliseconds: 500)).then((_) {
      _maybeShowPlayMenuTutorial();
    });
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
                StyledButton(
                  key: _startGameKey,
                  onPressed: _findOrCreateGame,
                  textStyle: TextStyle(
                    fontFamily: 'SpellOfAsia',
                    color: Colors.white,
                    fontSize: 32,
                  ),
                  text: l10n.startGame,
                ),
                10.0.spaceY,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      key: _pvpKey,
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
                      key: _aiKey,
                      onPressed: () => _showDifficultyDialog(context),
                      icon: Image.asset(
                        'assets/icons/robot.png',
                        width: 32,
                        color: Colors.white,
                      ),
                    ),
                    8.0.spaceX,
                    IconButton(
                      key: _privateKey,
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
    if (!await _ensureAuthenticated()) return;
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
    if (!await _ensureAuthenticated()) return;
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
    if (!await _ensureAuthenticated()) return;
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
        title: Text(
          l10n.matchmaking,
          style: TextStyle(
            fontFamily: 'SpellOfAsia',
          ),
        ),
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

  Future<bool> _ensureAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _playerUid = user.uid;
      return true;
    }
    final l10n = AppLocalizations.of(context)!;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loginRequiredTitle),
        content: Text(l10n.loginRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.loginRequiredAction),
          ),
        ],
      ),
    );
    if (shouldLogin == true && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    return false;
  }

  Future<void> _maybeShowPlayMenuTutorial() async {
    if (!mounted || _playMenuTutorialScheduled) {
      return;
    }
    final shouldShow = await TutorialService.shouldShow(TutorialFlow.playMenu);
    if (!shouldShow || !mounted) {
      return;
    }
    _playMenuTutorialScheduled = true;
    const attempts = 6;
    var ready = _areTargetsReady();
    var tries = 0;
    while (!ready && tries < attempts && mounted) {
      await Future.delayed(const Duration(milliseconds: 150));
      ready = _areTargetsReady();
      tries++;
    }
    if (!ready || !mounted) {
      _playMenuTutorialScheduled = false;
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    TutorialCoachMark(
      targets: _buildTargets(l10n),
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: l10n.tutorialSkip,
      paddingFocus: 12,
      onFinish: () => unawaited(TutorialService.markCompleted(TutorialFlow.playMenu)),
      onSkip: () {
        unawaited(TutorialService.markCompleted(TutorialFlow.playMenu));
        return true;
      },
    ).show(context: context);
  }

  bool _areTargetsReady() {
    return _startGameKey.currentContext != null && _pvpKey.currentContext != null && _aiKey.currentContext != null && _privateKey.currentContext != null;
  }

  List<TargetFocus> _buildTargets(AppLocalizations l10n) {
    return [
      TargetFocus(
        identify: 'start-game',
        keyTarget: _startGameKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            child: TutorialCard(
              title: l10n.tutorialPlayMenuStartTitle,
              description: l10n.tutorialPlayMenuStartDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'pvp',
        keyTarget: _pvpKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialPlayMenuPvpTitle,
              description: l10n.tutorialPlayMenuPvpDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ai',
        keyTarget: _aiKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialPlayMenuAiTitle,
              description: l10n.tutorialPlayMenuAiDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'private',
        keyTarget: _privateKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialPlayMenuPrivateTitle,
              description: l10n.tutorialPlayMenuPrivateDescription,
            ),
          ),
        ],
      ),
    ];
  }
}
