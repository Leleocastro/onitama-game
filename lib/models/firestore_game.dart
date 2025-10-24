import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './ai_difficulty.dart';
import './card_model.dart';
import './game_mode.dart';
import './piece.dart';
import './piece_type.dart';
import './player.dart';
import './point.dart';
import 'move.dart';

class FirestoreGame {
  final String id;
  final List<List<Piece?>> board;
  final List<CardModel> redHand;
  final List<CardModel> blueHand;
  final CardModel reserveCard;
  final PlayerColor currentPlayer;
  final PlayerColor? winner;
  final Map<String, dynamic>? lastMove;
  final Map<String, String> players;
  final Timestamp createdAt;
  final String status;
  final GameMode gameMode;
  final AIDifficulty? aiDifficulty;
  final List<Move> gameHistory;
  final List<Map<String, dynamic>>? stateHistory;

  FirestoreGame({
    required this.id,
    required this.board,
    required this.redHand,
    required this.blueHand,
    required this.reserveCard,
    required this.currentPlayer,
    required this.players,
    required this.createdAt,
    required this.status,
    required this.gameMode,
    this.winner,
    this.lastMove,
    this.aiDifficulty,
    this.gameHistory = const [],
    this.stateHistory,
  });

  factory FirestoreGame.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final boardData = data['board'] as List;
    final board = List.generate(5, (r) {
      return List.generate(5, (c) {
        final pieceData = boardData.firstWhere(
          (p) => p['row'] == r && p['col'] == c,
          // Retorna um mapa sentinela para evitar orElse retornar null e causar erro de tipo
          orElse: () => {'row': r, 'col': c, 'owner': '', 'type': ''},
        );
        if ((pieceData['owner'] as String).isEmpty) {
          return null;
        }
        return Piece(PlayerColor.values.firstWhere((e) => e.name == pieceData['owner']), PieceType.values.firstWhere((e) => e.name == pieceData['type']));
      });
    });

    return FirestoreGame(
      id: doc.id,
      board: board,
      redHand: (data['redHand'] as List)
          .map(
            (cardData) =>
                CardModel(cardData['name'], (cardData['moves'] as List).map((move) => Point(move['r'], move['c'])).toList(), Color(cardData['color'])),
          )
          .toList(),
      blueHand: (data['blueHand'] as List)
          .map(
            (cardData) =>
                CardModel(cardData['name'], (cardData['moves'] as List).map((move) => Point(move['r'], move['c'])).toList(), Color(cardData['color'])),
          )
          .toList(),
      reserveCard: CardModel(
        data['reserveCard']['name'],
        (data['reserveCard']['moves'] as List).map((move) => Point(move['r'], move['c'])).toList(),
        Color(data['reserveCard']['color']),
      ),
      currentPlayer: PlayerColor.values.firstWhere((e) => e.name == data['currentPlayer']),
      winner: data['winner'] == null ? null : PlayerColor.values.firstWhere((e) => e.name == data['winner']),
      lastMove: data['lastMove'] != null ? Map<String, dynamic>.from(data['lastMove']) : null,
      players: Map<String, String>.from(data['players']),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.fromMillisecondsSinceEpoch(data['createdAt']),
      status: data['status'] ?? 'inprogress',
      gameMode: GameMode.values.firstWhere((e) => e.name == data['gameMode'], orElse: () => GameMode.online),
      aiDifficulty: data['aiDifficulty'] == null ? null : AIDifficulty.values.firstWhere((e) => e.name == data['aiDifficulty']),
      gameHistory: data['gameHistory'] != null ? (data['gameHistory'] as List).map((move) => Move.fromMap(move)).toList() : [],
      stateHistory: data['stateHistory'] != null ? (data['stateHistory'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final flatBoard = <Map<String, dynamic>>[];
    for (var r = 0; r < board.length; r++) {
      for (var c = 0; c < board[r].length; c++) {
        final piece = board[r][c];
        flatBoard.add({'row': r, 'col': c, 'owner': piece?.owner.name ?? '', 'type': piece?.type.name ?? ''});
      }
    }

    List<Map<String, int>> movesToMap(List<Point> moves) {
      return moves.map((m) => {'r': m.r, 'c': m.c}).toList();
    }

    return {
      'board': flatBoard,
      'redHand': redHand.map((card) => {'name': card.name, 'moves': movesToMap(card.moves), 'color': card.color.toARGB32()}).toList(),
      'blueHand': blueHand.map((card) => {'name': card.name, 'moves': movesToMap(card.moves), 'color': card.color.toARGB32()}).toList(),
      'reserveCard': {'name': reserveCard.name, 'moves': movesToMap(reserveCard.moves), 'color': reserveCard.color.toARGB32()},
      'currentPlayer': currentPlayer.name,
      if (winner != null) 'winner': winner!.name,
      if (lastMove != null) 'lastMove': lastMove,
      if (players.isNotEmpty) 'players': players,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
      'gameMode': gameMode.name,
      if (aiDifficulty != null) 'aiDifficulty': aiDifficulty!.name,
      'gameHistory': gameHistory.map((move) => move.toMap()).toList(),
      if (stateHistory != null) 'stateHistory': stateHistory,
    };
  }

  FirestoreGame copyWith({
    List<List<Piece?>>? board,
    List<CardModel>? redHand,
    List<CardModel>? blueHand,
    CardModel? reserveCard,
    PlayerColor? currentPlayer,
    PlayerColor? winner,
    Map<String, dynamic>? lastMove,
    String? status,
    GameMode? gameMode,
    AIDifficulty? aiDifficulty,
    List<Move>? gameHistory,
    List<Map<String, dynamic>>? stateHistory,
  }) {
    return FirestoreGame(
      id: id,
      board: board ?? this.board,
      redHand: redHand ?? this.redHand,
      blueHand: blueHand ?? this.blueHand,
      reserveCard: reserveCard ?? this.reserveCard,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winner: winner ?? this.winner,
      lastMove: lastMove ?? this.lastMove,
      players: players,
      createdAt: createdAt,
      status: status ?? this.status,
      gameMode: gameMode ?? this.gameMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      gameHistory: gameHistory ?? this.gameHistory,
      stateHistory: stateHistory ?? this.stateHistory,
    );
  }
}
