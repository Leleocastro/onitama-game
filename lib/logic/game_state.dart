import 'package:flutter/material.dart';

import '../models/ai_difficulty.dart';
import '../models/card_model.dart';
import '../models/game_mode.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../models/point.dart';
import 'ai_player.dart';

class GameState {
  static const int size = 5;

  final GameMode gameMode;
  final AIDifficulty? aiDifficulty;
  AIPlayer? aiPlayer;

  List<List<Piece?>> board = List.generate(size, (_) => List.generate(size, (_) => null));

  late List<CardModel> allCards;
  List<CardModel> redHand = [];
  List<CardModel> blueHand = [];
  late CardModel reserveCard;

  PlayerColor currentPlayer = PlayerColor.blue;

  CardModel? selectedCardForMove;
  Point? selectedCell;
  String message = '';
  Move? lastMove;

  GameState({required this.gameMode, this.aiDifficulty}) {
    if (gameMode == GameMode.pvai) {
      aiPlayer = AIPlayer(aiDifficulty!);
    }
    _setupCards();
    _setupBoard();
  }

  GameState._internal({
    required this.gameMode,
    this.aiDifficulty,
    required this.board,
    required this.allCards,
    required this.redHand,
    required this.blueHand,
    required this.reserveCard,
    required this.currentPlayer,
    this.selectedCardForMove,
    this.selectedCell,
    required this.message,
    this.aiPlayer,
    this.lastMove,
  });

  GameState copy() {
    final newBoard = List.generate(size, (r) => List.generate(size, (c) => board[r][c]));
    return GameState._internal(
      gameMode: gameMode,
      aiDifficulty: aiDifficulty,
      board: newBoard,
      allCards: allCards,
      redHand: List.from(redHand),
      blueHand: List.from(blueHand),
      reserveCard: reserveCard,
      currentPlayer: currentPlayer,
      selectedCardForMove: selectedCardForMove,
      selectedCell: selectedCell,
      message: message,
      aiPlayer: aiPlayer,
      lastMove: lastMove,
    );
  }

  void _setupBoard() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        board[r][c] = null;
      }
    }

    board[0][0] = Piece(PlayerColor.red, PieceType.student);
    board[0][1] = Piece(PlayerColor.red, PieceType.student);
    board[0][2] = Piece(PlayerColor.red, PieceType.master);
    board[0][3] = Piece(PlayerColor.red, PieceType.student);
    board[0][4] = Piece(PlayerColor.red, PieceType.student);

    board[4][0] = Piece(PlayerColor.blue, PieceType.student);
    board[4][1] = Piece(PlayerColor.blue, PieceType.student);
    board[4][2] = Piece(PlayerColor.blue, PieceType.master);
    board[4][3] = Piece(PlayerColor.blue, PieceType.student);
    board[4][4] = Piece(PlayerColor.blue, PieceType.student);

    selectedCardForMove = null;
    selectedCell = null;
    currentPlayer = PlayerColor.blue;
    message = 'Blue starts!';
    lastMove = null;
  }

  void _setupCards() {
    allCards = [
      CardModel('Tiger', [Point(-1, 0), Point(2, 0)], Colors.orange),
      CardModel('Dragon', [Point(1, 2), Point(1, -2), Point(-1, 1), Point(-1, -1)], Colors.teal),
      CardModel('Frog', [Point(0, 2), Point(1, 1), Point(-1, -1)], Colors.cyan),
      CardModel('Rabbit', [Point(-1, 1), Point(1, -1), Point(0, -2)], Colors.pinkAccent),
      CardModel('Crab', [Point(0, -2), Point(0, 2), Point(1, 0)], Colors.blueGrey),
      CardModel('Elephant', [Point(0, -1), Point(0, 1), Point(1, -1), Point(1, 1)], Colors.purple),
      CardModel('Goose', [Point(0, -1), Point(0, 1), Point(-1, -1), Point(1, 1)], Colors.yellow),
      CardModel('Rooster', [Point(0, -1), Point(0, 1), Point(-1, 1), Point(1, -1)], Colors.deepOrangeAccent),
      CardModel('Monkey', [Point(-1, -1), Point(-1, 1), Point(1, -1), Point(1, 1)], Colors.brown),
      CardModel('Mantis', [Point(-1, -1), Point(-1, 1), Point(1, 0)], Colors.green),
      CardModel('Horse', [Point(-1, 0), Point(1, 0), Point(0, 1)], Colors.deepPurpleAccent),
      CardModel('Ox', [Point(-1, 0), Point(1, 0), Point(0, -1)], Colors.lightBlueAccent),
      CardModel('Crane', [Point(1, 0), Point(-1, 1), Point(-1, -1)], Colors.lightGreen),
      CardModel('Boar', [Point(0, -1), Point(0, 1), Point(1, 0)], Colors.redAccent),
      CardModel('Eel', [Point(1, 1), Point(-1, 1), Point(0, -1)], Colors.indigo),
      CardModel('Cobra', [Point(-1, -1), Point(1, -1), Point(0, 1)], Colors.amber),
    ];

    allCards.shuffle();
    redHand = [allCards[0], allCards[1]];
    blueHand = [allCards[2], allCards[3]];
    reserveCard = allCards[4];
  }

  bool _isInside(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  List<Point> availableMovesForCell(int r, int c, CardModel card, PlayerColor who) {
    final piece = board[r][c];
    if (piece == null || piece.owner != who) return [];

    bool isRed = who == PlayerColor.red;
    List<Point> targets = [];
    for (var mv in card.moves) {
      int dr = isRed ? mv.r : -mv.r;
      int dc = isRed ? mv.c : -mv.c;
      int nr = r + dr;
      int nc = c + dc;
      if (_isInside(nr, nc) && board[nr][nc]?.owner != who) {
        targets.add(Point(nr, nc));
      }
    }
    return targets;
  }

  void onCellTap(int r, int c, Function onWin) {
    if (gameMode == GameMode.pvai && currentPlayer == PlayerColor.blue) {
      return;
    }

    final piece = board[r][c];
    if ((selectedCell == null || piece != null) && (piece != null && piece.owner == currentPlayer)) {
      selectedCell = Point(r, c);
      message = 'Piece selected at ($r,$c)';
    } else if (selectedCardForMove != null) {
      final from = selectedCell!;
      final moves = availableMovesForCell(from.r, from.c, selectedCardForMove!, currentPlayer);
      bool allowed = moves.any((p) => p.r == r && p.c == c);

      if (!allowed) {
        message = 'Invalid move';
        return;
      }

      final moving = board[from.r][from.c];
      board[r][c] = moving;
      board[from.r][from.c] = null;

      lastMove = Move(from, Point(r, c), selectedCardForMove!);
      swapCardWithReserve(selectedCardForMove!);
      selectedCardForMove = null;
      selectedCell = null;

      if (isWinByCapture()) {
        onWin('${_playerName(currentPlayer)} won by capture!');
        return;
      }

      if (isWinByTemple(r, c, currentPlayer)) {
        onWin('${_playerName(currentPlayer)} won by temple!');
        return;
      }

      currentPlayer = opponent(currentPlayer);
      message = "${_playerName(currentPlayer)}'s turn";

      if (gameMode == GameMode.pvai && currentPlayer == PlayerColor.blue) {
        makeAIMove(onWin);
      }
    }
  }

  void makeAIMove(Function onWin) {
    final move = aiPlayer!.getMove(this);
    if (move == null) {
      onWin('${_playerName(currentPlayer)} has no moves! You win!');
      return;
    }

    final moving = board[move.from.r][move.from.c];
    board[move.to.r][move.to.c] = moving;
    board[move.from.r][move.from.c] = null;

    lastMove = move;
    swapCardWithReserve(move.card);

    if (isWinByCapture()) {
      onWin('${_playerName(currentPlayer)} won by capture!');
      return;
    }

    if (isWinByTemple(move.to.r, move.to.c, currentPlayer)) {
      onWin('${_playerName(currentPlayer)} won by temple!');
      return;
    }

    currentPlayer = opponent(currentPlayer);
    message = "${_playerName(currentPlayer)}'s turn";
  }

  void swapCardWithReserve(CardModel used) {
    List<CardModel> hand = currentPlayer == PlayerColor.red ? redHand : blueHand;
    int idx = hand.indexWhere((c) => c.name == used.name);
    if (idx == -1) return;
    hand[idx] = reserveCard;
    reserveCard = used;
  }

  bool isWinByCapture() {
    bool redMasterAlive = false;
    bool blueMasterAlive = false;
    for (var row in board) {
      for (var piece in row) {
        if (piece?.type == PieceType.master) {
          if (piece!.owner == PlayerColor.red) redMasterAlive = true;
          if (piece.owner == PlayerColor.blue) blueMasterAlive = true;
        }
      }
    }
    return !redMasterAlive || !blueMasterAlive;
  }

  bool isWinByTemple(int r, int c, PlayerColor who) {
    if (who == PlayerColor.red) {
      return r == 4 && c == 2 && board[r][c]?.type == PieceType.master;
    }
    return r == 0 && c == 2 && board[r][c]?.type == PieceType.master;
  }

  PlayerColor opponent(PlayerColor p) => p == PlayerColor.red ? PlayerColor.blue : PlayerColor.red;

  String _playerName(PlayerColor p) => p == PlayerColor.red ? 'Red' : 'Blue';

  void onCardTap(CardModel card) {
    if (gameMode == GameMode.pvai && currentPlayer == PlayerColor.blue) {
      return;
    }
    final hand = currentPlayer == PlayerColor.red ? redHand : blueHand;
    if (!hand.any((c) => c.name == card.name)) {
      message = 'Card does not belong to you';
      return;
    }
    selectedCardForMove = card;
    message = 'Card ${card.name} selected';
  }

  List<Point> invertMoves(List<Point> moves) {
    return moves.map((m) => Point((m.r * -1), (m.c * -1))).toList();
  }

  void restart() {
    _setupCards();
    _setupBoard();
  }
}
