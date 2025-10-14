import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onitama/models/firestore_game.dart';
import 'package:onitama/services/firestore_service.dart';

import '../logic/game_state.dart';
import '../models/ai_difficulty.dart';
import '../models/card_model.dart';
import '../models/game_mode.dart';
import '../models/player.dart';
import '../widgets/board_widget.dart';
import '../widgets/card_widget.dart';

class OnitamaHome extends StatefulWidget {
  final GameMode gameMode;
  final AIDifficulty? aiDifficulty;
  final String? gameId;
  final String? playerUid;
  final bool? isHost;

  const OnitamaHome({super.key, required this.gameMode, this.aiDifficulty, this.gameId, this.playerUid, this.isHost});

  @override
  OnitamaHomeState createState() => OnitamaHomeState();
}

class OnitamaHomeState extends State<OnitamaHome> {
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

    bool moveMade = false;
    setState(() {
      moveMade = _gameState!.onCellTap(r, c, _showEndDialog);
    });

    if (moveMade && widget.gameMode == GameMode.online) {
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

  Widget _buildHands(PlayerColor player) {
    final hand = player == PlayerColor.red ? _gameState!.redHand : _gameState!.blueHand;
    final isPlayerTurn = _gameState!.currentPlayer == player;

    return AbsorbPointer(
      absorbing: !isPlayerTurn,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hand
                .map(
                  (c) => CardWidget(
                    card: c,
                    isSelected: _gameState!.selectedCardForMove?.name == c.name,
                    onTap: _onCardTap,
                    invert: player == (widget.isHost! ? PlayerColor.blue : PlayerColor.red),
                  ),
                )
                .toList(),
          ),
        ],
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
          appBar: AppBar(
            title: Text(_gameState!.message),
            actions: [
              if (widget.gameMode != GameMode.online)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
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
          body: SafeArea(
            child: Column(
              children: [
                _buildHands(widget.isHost! ? PlayerColor.red : PlayerColor.blue),
                Expanded(
                  child: Center(
                    child: BoardWidget(gameState: _gameState!, onCellTap: _onCellTap, playerColor: widget.isHost! ? PlayerColor.blue : PlayerColor.red),
                  ),
                ),
                _buildHands(widget.isHost! ? PlayerColor.blue : PlayerColor.red),
                const Text('Reserve'),
                CardWidget(card: _gameState!.reserveCard, selectable: false, invert: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
