import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../models/point.dart';

class GameState {
  static const int size = 5;

  List<List<Piece?>> board = List.generate(size, (_) => List.generate(size, (_) => null));

  late List<CardModel> allCards;
  List<CardModel> redHand = [];
  List<CardModel> blueHand = [];
  late CardModel reserveCard;

  PlayerColor currentPlayer = PlayerColor.red;

  CardModel? selectedCardForMove;
  Point? selectedCell;
  String message = '';

  GameState() {
    _setupCards();
    _setupBoard();
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
    currentPlayer = PlayerColor.red;
    message = 'Red starts!';
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

      _swapCardWithReserve(selectedCardForMove!);
      selectedCardForMove = null;
      selectedCell = null;

      if (_isWinByCapture()) {
        onWin('${_playerName(currentPlayer)} won by capture!');
        return;
      }

      if (_isWinByTemple(r, c, currentPlayer)) {
        onWin('${_playerName(currentPlayer)} won by temple!');
        return;
      }

      currentPlayer = _opponent(currentPlayer);
      message = "${_playerName(currentPlayer)}'s turn";
    }
  }

  void _swapCardWithReserve(CardModel used) {
    List<CardModel> hand = currentPlayer == PlayerColor.red ? redHand : blueHand;
    int idx = hand.indexWhere((c) => c.name == used.name);
    if (idx == -1) return;
    hand[idx] = reserveCard;
    reserveCard = used;
  }

  bool _isWinByCapture() {
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

  bool _isWinByTemple(int r, int c, PlayerColor who) {
    if (who == PlayerColor.red) {
      return r == 4 && c == 2 && board[r][c]?.type == PieceType.master;
    }
    return r == 0 && c == 2 && board[r][c]?.type == PieceType.master;
  }

  PlayerColor _opponent(PlayerColor p) => p == PlayerColor.red ? PlayerColor.blue : PlayerColor.red;

  String _playerName(PlayerColor p) => p == PlayerColor.red ? 'Red' : 'Blue';

  void onCardTap(CardModel card) {
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
