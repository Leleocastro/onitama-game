import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../logic/game_state.dart';
import '../models/ai_difficulty.dart';
import '../models/card_model.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../models/win_condition.dart';
import '../services/firestore_service.dart';
import '../services/ranking_service.dart';
import '../services/theme_manager.dart';
import '../utils/extensions.dart';
import '../widgets/board_widget.dart';
import '../widgets/card_widget.dart';
import '../widgets/username_avatar.dart';
import 'historic_game_detail_screen.dart';
import 'interstitial_ad_screen.dart';
import 'rewarded_ad_screen.dart';

class OnitamaHome extends StatefulWidget {
  final GameMode gameMode;
  final AIDifficulty? aiDifficulty;
  final String? gameId;
  final String? playerUid;
  final bool? isHost;
  final bool hasDelay;

  const OnitamaHome({
    required this.gameMode,
    super.key,
    this.aiDifficulty,
    this.gameId,
    this.playerUid,
    this.isHost,
    this.hasDelay = false,
  });

  @override
  OnitamaHomeState createState() => OnitamaHomeState();
}

class OnitamaHomeState extends State<OnitamaHome> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  GameState? _gameState;
  final FirestoreService _firestoreService = FirestoreService();
  final RankingService _rankingService = RankingService();
  Stream<FirestoreGame>? _gameStream;
  StreamSubscription? _gameSubscription;
  FirestoreGame? _firestoreGame;
  bool _rankingSubmitted = false;
  final Map<String, String> _usernameCache = <String, String>{};
  final Set<String> _loadingUsernameUids = <String>{};
  final Map<String, int?> _ratingCache = <String, int?>{};
  final Set<String> _loadingRatingUids = <String>{};
  final Map<PlayerColor, String> _fallbackUsernames = <PlayerColor, String>{};
  final Random _random = Random();

  static const List<String> _fakeFirstNames = <String>[
    'Aiko',
    'Hiro',
    'Kenji',
    'Mika',
    'Ren',
    'Sora',
    'Taro',
    'Yumi',
    'Daichi',
    'Kumi',
  ];

  static const List<String> _fakeLastNames = <String>[
    'Tanaka',
    'Sato',
    'Nakamura',
    'Yamamoto',
    'Suzuki',
    'Fujimoto',
    'Kobayashi',
    'Hayashi',
    'Okada',
    'Shimizu',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.gameId != null) {
      _gameStream = _firestoreService.streamGame(widget.gameId!);
      _loadGameState();
    }

    if (widget.gameMode == GameMode.online) {
      _gameSubscription = _gameStream?.listen((firestoreGame) {
        _firestoreGame = firestoreGame;
        _maybeLoadPlayerProfiles(firestoreGame.players);
        final oldSelectedCell = _gameState?.selectedCell;
        final oldSelectedCard = _gameState?.selectedCardForMove;

        setState(() {
          _gameState = GameState.fromFirestore(
            firestoreGame,
            widget.gameMode,
            widget.aiDifficulty,
          );
          _gameState?.selectedCell = oldSelectedCell;
          _gameState?.selectedCardForMove = oldSelectedCard;
          if (_gameState?.lastMove == null && (ModalRoute.of(context)?.isCurrent != true)) {
            Navigator.of(context).pop();
          }

          _gameState?.verifyWin(_showEndDialog);
        });

        _submitRankingIfNeeded(firestoreGame);
      });
    } else {
      _gameState = GameState(
        gameMode: widget.gameMode,
        aiDifficulty: widget.aiDifficulty,
      );
    }
  }

  Future<void> _loadGameState() async {
    if (widget.gameId != null) {
      final firestoreGame = await _firestoreService.getGame(widget.gameId!);
      if (firestoreGame != null) {
        setState(() {
          _firestoreGame = firestoreGame;
          _gameState = GameState.fromFirestore(
            firestoreGame,
            widget.gameMode,
            widget.aiDifficulty,
          );
        });
        _maybeLoadPlayerProfiles(firestoreGame.players);
      }
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  void _onCellTap(int r, int c) {
    if (widget.gameMode == GameMode.online) {
      if ((_gameState!.currentPlayer == PlayerColor.red && widget.isHost!) || (_gameState!.currentPlayer == PlayerColor.blue && !widget.isHost!)) {
        return;
      }
    }

    final isAiTurn = _gameState!.onCellTap(r, c, _showEndDialog);
    setState(() {});

    if (isAiTurn) {
      _handleAIMove();
    }
  }

  Future<void> _handleAIMove() async {
    final isWinByCapture = _gameState!.isWinByCapture();
    final isWinByTemple = _gameState!.isWinByTemple(
      _gameState!.lastMove!.to.r,
      _gameState!.lastMove!.to.c,
      PlayerColor.blue,
    );
    if (_gameState!.gameMode == GameMode.pvai && !isWinByCapture && !isWinByTemple) {
      await _gameState!.makeAIMove(_showEndDialog, widget.hasDelay);
      setState(() {});
    }
    if (_firestoreGame != null && widget.gameMode == GameMode.online) {
      final updatedGame = _firestoreGame!.copyWith(
        board: _gameState!.board,
        redHand: _gameState!.redHand,
        blueHand: _gameState!.blueHand,
        reserveCard: _gameState!.reserveCard,
        currentPlayer: _gameState!.currentPlayer,
        lastMove: _gameState!.lastMoveAsMap,
        status: _gameState!.winner != null ? 'finished' : null,
        winner: _gameState!.winner,
        gameHistory: _gameState!.gameHistory,
      );
      _firestoreService.updateGame(widget.gameId!, updatedGame);
    }
  }

  void _onCardTap(CardModel card) {
    if (widget.gameMode == GameMode.online) {
      if ((_gameState!.currentPlayer == PlayerColor.red && widget.isHost!) || (_gameState!.currentPlayer == PlayerColor.blue && !widget.isHost!)) {
        return;
      }
    }

    setState(() {
      _gameState!.onCardTap(card);
    });
  }

  void _showEndDialog(PlayerColor winner, WinCondition condition) {
    final l10n = AppLocalizations.of(context)!;
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final winnerName = _getWinnerName(winner);
    final conditionText = condition == WinCondition.capture ? l10n.wonByCapture : l10n.wonByTemple;
    final text = '$winnerName $conditionText';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.gameOver),
        content: Text(text),
        actions: [
          TextButton(
            child: Text(l10n.exit),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Navigate back to menu
            },
          ),
          if (widget.gameMode == GameMode.pvai && winner == PlayerColor.red)
            TextButton(
              child: Text(l10n.undoWithAd),
              onPressed: () {
                Navigator.of(context).pop(); // fecha o diálogo
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RewardedAdScreen(
                      onReward: () async {
                        await _undoLastTwoAndPersist();
                      },
                    ),
                  ),
                );
              },
            ),
          if (_gameState!.gameMode == GameMode.pvp)
            TextButton(
              child: Text(l10n.restart),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: widget.gameMode,
                        aiDifficulty: widget.aiDifficulty,
                        gameId: widget.gameId,
                        playerUid: widget.playerUid,
                        isHost: widget.isHost,
                        hasDelay: widget.hasDelay,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _submitRankingIfNeeded(FirestoreGame game) async {
    if (_rankingSubmitted || widget.gameMode != GameMode.online || widget.gameId == null) {
      return;
    }
    if (game.status != 'finished') {
      return;
    }

    _rankingSubmitted = true;
    try {
      await _rankingService.submitMatchResult(widget.gameId!);
    } catch (error) {
      debugPrint('Failed to submit ranking for game ${widget.gameId}: $error');
      _rankingSubmitted = false;
    }
  }

  Future<void> _undoLastTwoAndPersist() async {
    if (_gameState == null) return;
    final ok = _gameState!.undoLastTwoMoves();
    if (!ok) return;
    setState(() {});
  }

  void _maybeLoadPlayerProfiles(Map<String, String> players) {
    if (widget.gameMode != GameMode.online) return;
    players.forEach((_, uid) {
      if (uid.isEmpty || uid == 'ai') return;
      _loadUsernameIfNeeded(uid);
      _loadRatingIfNeeded(uid);
    });
  }

  void _loadUsernameIfNeeded(String uid) {
    if (_usernameCache.containsKey(uid) || _loadingUsernameUids.contains(uid)) return;
    _loadingUsernameUids.add(uid);
    _firestoreService.getUsername(uid).then((username) {
      if (!mounted) return;
      setState(() {
        _usernameCache[uid] = username ?? '';
        _loadingUsernameUids.remove(uid);
      });
    }).catchError((error) {
      debugPrint('Failed to load username for $uid: $error');
      if (!mounted) return;
      setState(() {
        _usernameCache[uid] = '';
        _loadingUsernameUids.remove(uid);
      });
    });
  }

  void _loadRatingIfNeeded(String uid) {
    if (_ratingCache.containsKey(uid) || _loadingRatingUids.contains(uid)) return;
    _loadingRatingUids.add(uid);
    _rankingService.fetchPlayerEntry(uid).then((entry) {
      if (!mounted) return;
      setState(() {
        _ratingCache[uid] = entry?.rating;
        _loadingRatingUids.remove(uid);
      });
    }).catchError((error) {
      debugPrint('Failed to load rating for $uid: $error');
      if (!mounted) return;
      setState(() {
        _ratingCache[uid] = null;
        _loadingRatingUids.remove(uid);
      });
    });
  }

  String? _usernameForColor(PlayerColor color) {
    if (widget.gameMode != GameMode.online) {
      return null;
    }
    final players = _firestoreGame?.players;
    if (players == null) return null;
    final key = color == PlayerColor.blue ? 'blue' : 'red';
    final uid = players[key];
    if (uid == null || uid.isEmpty || uid == 'ai') {
      return null;
    }
    final username = _usernameCache[uid];
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return null;
  }

  int? _ratingForColor(PlayerColor color) {
    if (widget.gameMode != GameMode.online) {
      return null;
    }
    final players = _firestoreGame?.players;
    if (players == null) return null;
    final key = color == PlayerColor.blue ? 'blue' : 'red';
    final uid = players[key];
    if (uid == null || uid.isEmpty || uid == 'ai') {
      return null;
    }
    if (_ratingCache.containsKey(uid)) {
      return _ratingCache[uid];
    }
    return null;
  }

  String _fakeUsernameForColor(PlayerColor color) {
    return _fallbackUsernames.putIfAbsent(color, () {
      final first = _fakeFirstNames[_random.nextInt(_fakeFirstNames.length)];
      final last = _fakeLastNames[_random.nextInt(_fakeLastNames.length)];
      final suffix = (_random.nextInt(900) + 100).toString();
      return '$first$last$suffix';
    });
  }

  String _getWinnerName(PlayerColor winner) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.gameMode == GameMode.online) {
      final username = _usernameForColor(winner);
      if (username != null) {
        return username;
      }
      return _fakeUsernameForColor(winner);
    } else {
      return winner == PlayerColor.blue ? l10n.blue : l10n.red;
    }
  }

  String _getPlayerLabel(PlayerColor player) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.gameMode == GameMode.online) {
      final username = _usernameForColor(player);
      if (username != null) {
        return username;
      }
      return _fakeUsernameForColor(player);
    }
    if (widget.gameMode == GameMode.pvp) {
      return player == PlayerColor.red ? l10n.red : l10n.blue;
    }
    if (widget.isHost!) {
      // Host is always blue
      return player == PlayerColor.blue ? l10n.you : l10n.opponent;
    } else {
      // Guest is always red
      return player == PlayerColor.red ? l10n.you : l10n.opponent;
    }
  }

  String _getLocalizedCardName(BuildContext context, String cardName) {
    final l10n = AppLocalizations.of(context)!;
    switch (cardName) {
      case 'Tiger':
        return l10n.cardTiger;
      case 'Dragon':
        return l10n.cardDragon;
      case 'Frog':
        return l10n.cardFrog;
      case 'Rabbit':
        return l10n.cardRabbit;
      case 'Crab':
        return l10n.cardCrab;
      case 'Elephant':
        return l10n.cardElephant;
      case 'Goose':
        return l10n.cardGoose;
      case 'Rooster':
        return l10n.cardRooster;
      case 'Monkey':
        return l10n.cardMonkey;
      case 'Mantis':
        return l10n.cardMantis;
      case 'Horse':
        return l10n.cardHorse;
      case 'Ox':
        return l10n.cardOx;
      case 'Crane':
        return l10n.cardCrane;
      case 'Boar':
        return l10n.cardBoar;
      case 'Eel':
        return l10n.cardEel;
      case 'Cobra':
        return l10n.cardCobra;
      default:
        return cardName; // Fallback to original name if not found
    }
  }

  Widget _buildHands(PlayerColor player) {
    final hand = player == PlayerColor.red ? _gameState!.redHand : _gameState!.blueHand;
    final isPlayerTurn = _gameState!.currentPlayer == player;
    final isOnline = widget.gameMode == GameMode.online;

    return AbsorbPointer(
      absorbing: !isPlayerTurn,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: isOnline ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
          children: [
            if (!isOnline)
              Text(
                _getPlayerLabel(player),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: player == PlayerColor.red ? Colors.red : Colors.blue,
                  decoration: isPlayerTurn ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: player == PlayerColor.red ? Colors.red : Colors.blue,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: hand
                  .map(
                    (c) => CardWidget(
                      card: c,
                      localizedName: _getLocalizedCardName(context, c.name),
                      color: player == PlayerColor.red ? Colors.red : Colors.blue,
                      isSelected: _gameState!.selectedCardForMove?.name == c.name,
                      onTap: _onCardTap,
                      invert: player == (widget.isHost! ? PlayerColor.blue : PlayerColor.red),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = ThemeManager.cachedImage('default-background');
    final background = bgImage != null
        ? Image(
            image: bgImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : null;

    final l10n = AppLocalizations.of(context)!;
    if (_gameState == null) {
      return Scaffold(
        backgroundColor: background != null ? Colors.transparent : null,
        body: Center(
          child: Text(l10n.loading),
        ),
      );
    }
    final player = widget.isHost! ? PlayerColor.blue : PlayerColor.red;
    final opponentPlayer = player == PlayerColor.red ? PlayerColor.blue : PlayerColor.red;
    final isPlayerTurn = _gameState!.currentPlayer == player;
    final username = _getPlayerLabel(player);
    final opponentUsername = _getPlayerLabel(opponentPlayer);
    final playerRating = _ratingForColor(player);
    final opponentRating = _ratingForColor(opponentPlayer);

    return StreamBuilder(
      stream: widget.gameMode == GameMode.online ? _gameStream : null,
      builder: (context, asyncSnapshot) {
        if (widget.gameMode == GameMode.online && asyncSnapshot.connectionState == ConnectionState.waiting && _gameState == null) {
          return Scaffold(body: Center(child: Text(l10n.loading)));
        }
        return Stack(
          children: [
            if (background != null) background,
            Scaffold(
              key: scaffoldKey,
              backgroundColor: background != null ? Colors.transparent : null,
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.settings),
                onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
              ),
              endDrawer: Drawer(
                child: SafeArea(
                  child: Column(
                    children: [
                      widget.gameMode != GameMode.online
                          ? ListTile(
                              leading: const Icon(Icons.refresh),
                              title: Text(l10n.restartGame),
                              onTap: () async {
                                final shouldRestart = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.restartGame),
                                    content: Text(l10n.areYouSureRestart),
                                    actions: [
                                      TextButton(
                                        child: Text(l10n.cancel),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(l10n.restart),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldRestart == true) {
                                  Navigator.of(context).pop(); // Close the drawer
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => InterstitialAdScreen(
                                        navigateTo: OnitamaHome(
                                          gameMode: widget.gameMode,
                                          aiDifficulty: widget.aiDifficulty,
                                          gameId: widget.gameId,
                                          playerUid: widget.playerUid,
                                          isHost: widget.isHost,
                                          hasDelay: widget.hasDelay,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : ListTile(
                              leading: const Icon(Icons.flag_outlined),
                              title: Text(l10n.surrender),
                              onTap: () async {
                                final shouldSurrender = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.surrenderGame),
                                    content: Text(l10n.areYouSureSurrender),
                                    actions: [
                                      TextButton(
                                        child: Text(l10n.cancel),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(l10n.surrender),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldSurrender == true) {
                                  // Finaliza a partida, define o adversário como winner e status como finished
                                  if (_firestoreGame != null && widget.gameMode == GameMode.online) {
                                    final opponentColor = widget.isHost! ? PlayerColor.red : PlayerColor.blue;
                                    final updatedGame = _firestoreGame!.copyWith(
                                      status: 'finished',
                                      winner: opponentColor,
                                    );
                                    await _firestoreService.updateGame(
                                      widget.gameId!,
                                      updatedGame,
                                    );
                                  }
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop(); // Volta ao menu
                                }
                              },
                            ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(l10n.currentGameHistory),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => HistoricGameDetailScreen(
                                moves: _gameState!.gameHistory,
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      if (widget.gameMode != GameMode.online)
                        ListTile(
                          leading: const Icon(Icons.exit_to_app),
                          title: Text(l10n.exitGame),
                          onTap: () async {
                            final shouldExit = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(l10n.exitGame),
                                content: Text(l10n.areYouSureExit),
                                actions: [
                                  TextButton(
                                    child: Text(l10n.cancel),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: Text(l10n.exit),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            );
                            if (shouldExit == true) {
                              Navigator.of(context).pop(); // Close the drawer
                              Navigator.of(context).pop(); // Navigate back to menu
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (widget.gameMode == GameMode.online) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isPlayerTurn
                                          ? player == PlayerColor.red
                                              ? Colors.red
                                              : Colors.blue
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: UsernameAvatar(
                                    username: username,
                                    size: 30,
                                  ),
                                ),
                                8.0.spaceX,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: player == PlayerColor.red ? Colors.red : Colors.blue,
                                        decorationColor: player == PlayerColor.red ? Colors.red : Colors.blue,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star_border, size: 12, color: Colors.grey),
                                        4.0.spaceX,
                                        Text(
                                          playerRating != null ? '$playerRating' : '1200',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      opponentUsername,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: opponentPlayer == PlayerColor.red ? Colors.red : Colors.blue,
                                        decorationColor: opponentPlayer == PlayerColor.red ? Colors.red : Colors.blue,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          opponentRating != null ? '$opponentRating' : '1200',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        4.0.spaceX,
                                        const Icon(Icons.star_border, size: 12, color: Colors.grey),
                                      ],
                                    ),
                                  ],
                                ),
                                8.0.spaceX,
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: !isPlayerTurn
                                          ? opponentPlayer == PlayerColor.red
                                              ? Colors.red
                                              : Colors.blue
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: UsernameAvatar(
                                    username: opponentUsername,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        10.0.spaceY,
                      ],
                      _buildHands(
                        widget.isHost! ? PlayerColor.red : PlayerColor.blue,
                      ),
                      Expanded(
                        child: Center(
                          child: BoardWidget(
                            gameState: _gameState!,
                            onCellTap: _onCellTap,
                            playerColor: widget.isHost! ? PlayerColor.blue : PlayerColor.red,
                          ),
                        ),
                      ),
                      _buildHands(
                        widget.isHost! ? PlayerColor.blue : PlayerColor.red,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CardWidget(
                          card: _gameState!.reserveCard,
                          localizedName: _getLocalizedCardName(
                            context,
                            _gameState!.reserveCard.name,
                          ),
                          selectable: false,
                          invert: true,
                          color: Colors.green,
                          isReserve: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
