import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../models/ai_difficulty.dart';
import '../models/card_model.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../services/firestore_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/card_widget.dart';

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
  Stream<FirestoreGame>? _gameStream;
  StreamSubscription? _gameSubscription;
  FirestoreGame? _firestoreGame;

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
        final oldSelectedCell = _gameState?.selectedCell;
        final oldSelectedCard = _gameState?.selectedCardForMove;

        setState(() {
          _gameState = GameState.fromFirestore(firestoreGame, widget.gameMode, widget.aiDifficulty);
          _gameState?.selectedCell = oldSelectedCell;
          _gameState?.selectedCardForMove = oldSelectedCard;
          if (_gameState?.lastMove == null && (ModalRoute.of(context)?.isCurrent != true)) {
            Navigator.of(context).pop();
          }

          _gameState?.verifyWin(_showEndDialog);
        });
      });
    } else {
      _gameState = GameState(gameMode: widget.gameMode, aiDifficulty: widget.aiDifficulty);
    }
  }

  Future<void> _loadGameState() async {
    if (widget.gameId != null) {
      final firestoreGame = await _firestoreService.getGame(widget.gameId!);
      if (firestoreGame != null) {
        setState(() {
          _gameState = GameState.fromFirestore(firestoreGame, widget.gameMode, widget.aiDifficulty);
        });
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

    if (isAiTurn && !_gameState!.isWinByCapture() && !_gameState!.isWinByTemple(_gameState!.lastMove!.to.r, _gameState!.lastMove!.to.c, PlayerColor.blue)) {
      _handleAIMove();
    }
  }

  Future<void> _handleAIMove() async {
    if (_gameState!.gameMode == GameMode.pvai) {
      await _gameState!.makeAIMove(_showEndDialog, widget.hasDelay);
      setState(() {});
    }
    if (_gameState!.gameMode == GameMode.online) {
      if (_firestoreGame != null) {
        final updatedGame = _firestoreGame!.copyWith(
          board: _gameState!.board,
          redHand: _gameState!.redHand,
          blueHand: _gameState!.blueHand,
          reserveCard: _gameState!.reserveCard,
          currentPlayer: _gameState!.currentPlayer,
          lastMove: _gameState!.lastMoveAsMap,
        );
        _firestoreService.updateGame(widget.gameId!, updatedGame);
      }
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

  void _showEndDialog(String text) {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(text),
        actions: [
          TextButton(
            child: const Text('Exit'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Navigate back to menu
            },
          ),
          TextButton(
            child: const Text('Restart'),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _gameState!.restart();
                if (widget.gameMode == GameMode.online) {
                  if (_firestoreGame != null) {
                    final updatedGame = _firestoreGame!.copyWith(
                      board: _gameState!.board,
                      redHand: _gameState!.redHand,
                      blueHand: _gameState!.blueHand,
                      reserveCard: _gameState!.reserveCard,
                      currentPlayer: _gameState!.currentPlayer,
                      lastMove: {},
                    );
                    _firestoreService.updateGame(widget.gameId!, updatedGame);
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  String _getPlayerLabel(PlayerColor player) {
    if (widget.isHost!) {
      // Host is always blue
      return player == PlayerColor.blue ? 'You' : 'Opponent';
    } else {
      // Guest is always red
      return player == PlayerColor.red ? 'You' : 'Opponent';
    }
  }

  Widget _buildHands(PlayerColor player) {
    final hand = player == PlayerColor.red ? _gameState!.redHand : _gameState!.blueHand;
    final isPlayerTurn = _gameState!.currentPlayer == player;

    return AbsorbPointer(
      absorbing: !isPlayerTurn,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: hand
                  .map(
                    (c) => CardWidget(
                      card: c,
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
    if (_gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StreamBuilder(
      stream: widget.gameMode == GameMode.online ? _gameStream : null,
      builder: (context, asyncSnapshot) {
        if (widget.gameMode == GameMode.online && asyncSnapshot.connectionState == ConnectionState.waiting && _gameState == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          key: scaffoldKey,
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.settings),
            onPressed: scaffoldKey.currentState?.openEndDrawer,
          ),
          endDrawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  widget.gameMode != GameMode.online
                      ? ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Restart Game'),
                          onTap: () async {
                            final shouldRestart = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Restart Game'),
                                content: const Text('Are you sure you want to restart the game?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Restart'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            );
                            if (shouldRestart == true) {
                              Navigator.of(context).pop(); // Close the drawer
                              setState(() {
                                _gameState!.restart();
                                if (widget.gameMode == GameMode.online) {
                                  if (_firestoreGame != null) {
                                    final updatedGame = _firestoreGame!.copyWith(
                                      board: _gameState!.board,
                                      redHand: _gameState!.redHand,
                                      blueHand: _gameState!.blueHand,
                                      reserveCard: _gameState!.reserveCard,
                                      currentPlayer: _gameState!.currentPlayer,
                                      lastMove: {},
                                    );
                                    _firestoreService.updateGame(widget.gameId!, updatedGame);
                                  }
                                }
                              });
                            }
                          },
                        )
                      : ListTile(
                          leading: const Icon(Icons.flag_outlined),
                          title: const Text('Surrender'),
                          onTap: () async {
                            final shouldSurrender = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Surrender Game'),
                                content: const Text('Are you sure you want to surrender the game?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Surrender'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            );
                            if (shouldSurrender == true) {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(); // Navigate back to menu
                            }
                          },
                        ),
                  Spacer(),
                  if (widget.gameMode != GameMode.online)
                    ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      onTap: () async {
                        final shouldExit = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Exit Game'),
                            content: const Text('Are you sure you want to exit to the menu?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                              ),
                              TextButton(
                                child: const Text('Exit'),
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
                  _buildHands(widget.isHost! ? PlayerColor.red : PlayerColor.blue),
                  Expanded(
                    child: Center(
                      child: BoardWidget(gameState: _gameState!, onCellTap: _onCellTap, playerColor: widget.isHost! ? PlayerColor.blue : PlayerColor.red),
                    ),
                  ),
                  _buildHands(widget.isHost! ? PlayerColor.blue : PlayerColor.red),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CardWidget(card: _gameState!.reserveCard, selectable: false, invert: true, color: Colors.green, isReserve: true),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
