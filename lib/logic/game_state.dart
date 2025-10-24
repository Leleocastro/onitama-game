import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/ai_difficulty.dart';
import '../models/card_model.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../models/point.dart';
import '../models/win_condition.dart';
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
  PlayerColor? winner;

  CardModel? selectedCardForMove;
  Point? selectedCell;
  String message = '';
  Move? lastMove;
  List<Move> gameHistory = [];
  // Histórico de snapshots completos do estado do jogo para desfazer jogadas
  List<Map<String, dynamic>> stateHistory = [];

  GameState({required this.gameMode, this.aiDifficulty}) {
    if (gameMode == GameMode.pvai) {
      aiPlayer = AIPlayer(aiDifficulty!);
    }
    _setupCards();
    _setupBoard();
    winner = null;
  }

  GameState._internal({
    required this.gameMode,
    required this.board,
    required this.allCards,
    required this.redHand,
    required this.blueHand,
    required this.reserveCard,
    required this.currentPlayer,
    required this.message,
    this.aiDifficulty,
    this.selectedCardForMove,
    this.selectedCell,
    this.aiPlayer,
    this.lastMove,
    this.winner,
    this.gameHistory = const [],
  });

  factory GameState.fromFirestore(FirestoreGame firestoreGame, GameMode gameMode, AIDifficulty? aiDifficulty) {
    final gameState = GameState._internal(
      gameMode: firestoreGame.gameMode,
      aiDifficulty: firestoreGame.aiDifficulty ?? aiDifficulty,
      board: firestoreGame.board,
      allCards: [], // Temporarily empty, will be filled by _setupCards
      redHand: firestoreGame.redHand,
      blueHand: firestoreGame.blueHand,
      reserveCard: firestoreGame.reserveCard,
      currentPlayer: firestoreGame.currentPlayer,
      message: '${firestoreGame.currentPlayer.name} to move',
      lastMove: firestoreGame.lastMove != null && firestoreGame.lastMove!.isNotEmpty
          ? Move(
              Point(firestoreGame.lastMove!['from'][0], firestoreGame.lastMove!['from'][1]),
              Point(firestoreGame.lastMove!['to'][0], firestoreGame.lastMove!['to'][1]),
              CardModel(
                firestoreGame.lastMove!['card']['name'],
                (firestoreGame.lastMove!['card']['moves'] as List).map((move) => Point(move['r'], move['c'])).toList(),
                Color(firestoreGame.lastMove!['card']['color']),
              ),
            )
          : null,
      winner: firestoreGame.winner,
      gameHistory: firestoreGame.gameHistory,
    );
    gameState._setupCards(firestoreGame.redHand, firestoreGame.blueHand, firestoreGame.reserveCard);
    if (firestoreGame.gameMode == GameMode.pvai) {
      gameState.aiPlayer = AIPlayer(firestoreGame.aiDifficulty ?? aiDifficulty!);
    }
    return gameState;
  }

  Map<String, dynamic>? get lastMoveAsMap {
    if (lastMove == null) return null;
    return {
      'from': [lastMove!.from.r, lastMove!.from.c],
      'to': [lastMove!.to.r, lastMove!.to.c],
      'card': {
        'name': lastMove!.card.name,
        'moves': lastMove!.card.moves.map((move) => {'r': move.r, 'c': move.c}).toList(),
        'color': lastMove!.card.color.toARGB32(),
      },
    };
  }

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
      gameHistory: List.from(gameHistory),
      // não copiamos stateHistory por ser uma estrutura de controle separada
    );
  }

  // Serializa o estado completo do jogo para um snapshot leve
  Map<String, dynamic> toSnapshot() {
    final flatBoard = <Map<String, dynamic>>[];
    for (var r = 0; r < board.length; r++) {
      for (var c = 0; c < board[r].length; c++) {
        final piece = board[r][c];
        flatBoard.add({'row': r, 'col': c, 'owner': piece?.owner.name ?? '', 'type': piece?.type.name ?? ''});
      }
    }

    List<Map<String, int>> movesToMap(List<Point> moves) => moves.map((m) => {'r': m.r, 'c': m.c}).toList();

    return {
      'board': flatBoard,
      'redHand': redHand.map((card) => {'name': card.name, 'moves': movesToMap(card.moves), 'color': card.color.toARGB32()}).toList(),
      'blueHand': blueHand.map((card) => {'name': card.name, 'moves': movesToMap(card.moves), 'color': card.color.toARGB32()}).toList(),
      'reserveCard': {'name': reserveCard.name, 'moves': movesToMap(reserveCard.moves), 'color': reserveCard.color.toARGB32()},
      'currentPlayer': currentPlayer.name,
      'winner': winner?.name,
      'lastMove': lastMoveAsMap,
      'gameHistory': gameHistory.map((m) => m.toMap()).toList(),
      'gameMode': gameMode.name,
      'aiDifficulty': aiDifficulty?.name,
    };
  }

  // Restaura o estado a partir de um snapshot
  void restoreFromSnapshot(Map<String, dynamic> snap) {
    final boardData = snap['board'] as List;
    board = List.generate(5, (r) {
      return List.generate(5, (c) {
        final pieceMap = boardData.cast<Map<String, dynamic>>().firstWhere(
              (p) => p['row'] == r && p['col'] == c,
              orElse: () => <String, dynamic>{'owner': '', 'type': ''},
            );
        if ((pieceMap['owner'] as String).isEmpty) {
          return null;
        }
        return Piece(
          PlayerColor.values.firstWhere((e) => e.name == pieceMap['owner']),
          PieceType.values.firstWhere((e) => e.name == pieceMap['type']),
        );
      });
    });

    List<Point> mapToMoves(List list) => list.map((m) => Point(m['r'], m['c'])).toList();

    redHand = (snap['redHand'] as List).map((card) => CardModel(card['name'], mapToMoves(card['moves']), Color(card['color']))).toList();
    blueHand = (snap['blueHand'] as List).map((card) => CardModel(card['name'], mapToMoves(card['moves']), Color(card['color']))).toList();
    final rc = snap['reserveCard'];
    reserveCard = CardModel(rc['name'], mapToMoves(rc['moves']), Color(rc['color']));

    currentPlayer = PlayerColor.values.firstWhere((e) => e.name == snap['currentPlayer']);
    winner = snap['winner'] == null ? null : PlayerColor.values.firstWhere((e) => e.name == snap['winner']);

    if (snap['lastMove'] != null) {
      final lm = snap['lastMove'] as Map<String, dynamic>;
      lastMove = Move(
        Point(lm['from'][0], lm['from'][1]),
        Point(lm['to'][0], lm['to'][1]),
        CardModel(
          lm['card']['name'],
          (lm['card']['moves'] as List).map((m) => Point(m['r'], m['c'])).toList(),
          Color(lm['card']['color']),
        ),
      );
    } else {
      lastMove = null;
    }

    gameHistory = (snap['gameHistory'] as List).map((m) => Move.fromMap(m)).toList();
  }

  // Armazena o snapshot atual (limitando o tamanho para evitar crescer demais)
  void pushSnapshot({int maxLength = 40}) {
    stateHistory.add(toSnapshot());
    if (stateHistory.length > maxLength) {
      stateHistory.removeAt(0);
    }
  }

  // Desfaz as duas últimas jogadas (a do oponente e a sua)
  bool undoLastTwoMoves() {
    if (stateHistory.length < 3) return false;
    // Estado desejado é o de 2 jogadas atrás
    final target = stateHistory[stateHistory.length - 3];
    // remove os dois últimos snapshots
    stateHistory.removeLast();
    stateHistory.removeLast();
    // Restaura
    restoreFromSnapshot(target);
    // Após restaurar, a vez deve ser do oponente do jogador do snapshot
    currentPlayer = opponent(currentPlayer);
    // Ao desfazer, não deve haver vencedor
    winner = null;
    return true;
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

  void _setupCards([List<CardModel>? rHand, List<CardModel>? bHand, CardModel? resCard]) {
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
      CardModel('Mantis', [Point(1, 1), Point(1, -1), Point(-1, 0)], Colors.green),
      CardModel('Horse', [Point(-1, 0), Point(1, 0), Point(0, 1)], Colors.deepPurpleAccent),
      CardModel('Ox', [Point(-1, 0), Point(1, 0), Point(0, -1)], Colors.lightBlueAccent),
      CardModel('Crane', [Point(1, 0), Point(-1, 1), Point(-1, -1)], Colors.lightGreen),
      CardModel('Boar', [Point(0, -1), Point(0, 1), Point(1, 0)], Colors.redAccent),
      CardModel('Eel', [Point(1, 1), Point(-1, 1), Point(0, -1)], Colors.indigo),
      CardModel('Cobra', [Point(-1, -1), Point(1, -1), Point(0, 1)], Colors.amber),
    ];

    allCards.shuffle();
    redHand = rHand ?? [allCards[0], allCards[1]];
    blueHand = bHand ?? [allCards[2], allCards[3]];
    reserveCard = resCard ?? allCards[4];
  }

  bool _isInside(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  List<Point> availableMovesForCell(int r, int c, CardModel card, PlayerColor who) {
    final piece = board[r][c];
    if (piece == null || piece.owner != who) return [];

    final isRed = who == PlayerColor.red;
    final targets = <Point>[];
    for (final mv in card.moves) {
      final dr = isRed ? mv.r : -mv.r;
      final dc = isRed ? mv.c : -mv.c;
      final nr = r + dr;
      final nc = c + dc;
      if (_isInside(nr, nc) && board[nr][nc]?.owner != who) {
        targets.add(Point(nr, nc));
      }
    }
    return targets;
  }

  void verifyWin(Function(PlayerColor, WinCondition) onWin) {
    if (isWinByCapture()) {
      winner = currentPlayer;
      onWin(winner!, WinCondition.capture);
      return;
    }
    for (var c = 0; c < size; c++) {
      if (isWinByTemple(0, c, PlayerColor.red)) {
        winner = PlayerColor.red;
        onWin(PlayerColor.red, WinCondition.temple);
        return;
      }
      if (isWinByTemple(4, c, PlayerColor.blue)) {
        winner = PlayerColor.blue;
        onWin(PlayerColor.blue, WinCondition.temple);
        return;
      }
    }
    return;
  }

  bool onCellTap(int r, int c, Function(PlayerColor, WinCondition) onWin) {
    if (gameMode == GameMode.pvai && currentPlayer == PlayerColor.red) {
      return false;
    }

    final piece = board[r][c];
    if ((selectedCell == null || piece != null) && (piece != null && piece.owner == currentPlayer)) {
      selectedCell = Point(r, c);
      message = 'Piece selected at ($r,$c)';
      return false;
    } else if (selectedCardForMove != null) {
      final from = selectedCell!;
      final moves = availableMovesForCell(from.r, from.c, selectedCardForMove!, currentPlayer);
      final allowed = moves.any((p) => p.r == r && p.c == c);

      if (!allowed) {
        message = 'Invalid move';
        return false;
      }

      final moving = board[from.r][from.c];
      board[r][c] = moving;
      board[from.r][from.c] = null;

      lastMove = Move(from, Point(r, c), selectedCardForMove!);
      gameHistory.add(lastMove!);
      swapCardWithReserve(selectedCardForMove!);
      selectedCardForMove = null;
      selectedCell = null;

      if (isWinByCapture()) {
        winner = currentPlayer;
        onWin(winner!, WinCondition.capture);
        return true;
      }
      if (isWinByTemple(r, c, currentPlayer)) {
        winner = currentPlayer;
        onWin(winner!, WinCondition.temple);
        return true;
      }

      currentPlayer = opponent(currentPlayer);
      message = "${_playerName(currentPlayer)}'s turn";

      if (gameMode != GameMode.pvai) {
        pushSnapshot();
        return true;
      }

      pushSnapshot();
      return gameMode == GameMode.pvai && currentPlayer == PlayerColor.red;
    }
    return false;
  }

  Future<void> makeAIMove(Function(PlayerColor, WinCondition) onWin, [bool hasDelay = false]) async {
    final delay = hasDelay ? Duration(seconds: Random().nextInt(10) + 3) : Duration.zero;
    await Future.delayed(delay);

    final move = aiPlayer!.getMove(this);
    if (move == null) {
      winner = opponent(currentPlayer);
      onWin(winner!, WinCondition.capture);
      return;
    }

    final moving = board[move.from.r][move.from.c];
    board[move.to.r][move.to.c] = moving;
    board[move.from.r][move.from.c] = null;

    lastMove = move;
    gameHistory.add(lastMove!);
    swapCardWithReserve(move.card);
    // Registrar snapshot da jogada da IA antes de verificar vitória
    pushSnapshot();

    if (isWinByCapture()) {
      winner = currentPlayer;
      onWin(winner!, WinCondition.capture);
      return;
    }
    if (isWinByTemple(move.to.r, move.to.c, currentPlayer)) {
      winner = currentPlayer;
      onWin(winner!, WinCondition.temple);
      return;
    }

    currentPlayer = opponent(currentPlayer);
    message = "${_playerName(currentPlayer)}'s turn";
  }

  void swapCardWithReserve(CardModel used) {
    final hand = currentPlayer == PlayerColor.red ? redHand : blueHand;
    final idx = hand.indexWhere((c) => c.name == used.name);
    if (idx == -1) return;
    hand[idx] = reserveCard;
    reserveCard = used;
  }

  bool isWinByCapture() {
    var redMasterAlive = false;
    var blueMasterAlive = false;
    for (final row in board) {
      for (final piece in row) {
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
    if (gameMode == GameMode.pvai && currentPlayer == PlayerColor.red) {
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
    winner = null;
  }
}
