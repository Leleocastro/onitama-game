import 'dart:math';

import '../models/ai_difficulty.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../models/point.dart';
import 'game_state.dart';

class AIPlayer {
  final AIDifficulty difficulty;

  AIPlayer(this.difficulty);

  Move? getMove(GameState gameState) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return _getRandomMove(gameState);
      case AIDifficulty.medium:
        return _getGreedyMove(gameState);
      case AIDifficulty.hard:
        return _getAlphaBetaMove(gameState);
    }
  }

  Move? _getRandomMove(GameState gameState) {
    final possibleMoves = _getAllPossibleMoves(gameState);
    if (possibleMoves.isEmpty) {
      return null;
    }
    return possibleMoves[Random().nextInt(possibleMoves.length)];
  }

  Move? _getGreedyMove(GameState gameState) {
    final possibleMoves = _getAllPossibleMoves(gameState);
    if (possibleMoves.isEmpty) {
      return null;
    }

    Move? bestMove;
    int bestScore = -1;

    for (final move in possibleMoves) {
      final score = _getMoveScore(gameState, move);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove ?? _getRandomMove(gameState);
  }

  int _getMoveScore(GameState gameState, Move move) {
    int score = 0;
    final piece = gameState.board[move.from.r][move.from.c];
    final destinationPiece = gameState.board[move.to.r][move.to.c];

    if (destinationPiece != null) {
      if (destinationPiece.type == PieceType.master) {
        score += 100;
      } else {
        score += 10;
      }
    }

    if (piece!.type == PieceType.master) {
      if (gameState.currentPlayer == PlayerColor.blue && move.to.r < move.from.r) {
        score += 5;
      }
    } else {
      if (gameState.currentPlayer == PlayerColor.blue && move.to.r < move.from.r) {
        score += 1;
      }
    }

    return score;
  }

  Move? _getAlphaBetaMove(GameState gameState) {
    Move? bestMove;
    int bestValue = -99999;

    final moves = _getAllPossibleMoves(gameState);
    for (final move in moves) {
      final newState = gameState.copy();
      _applyMove(newState, move);
      final value = _minimax(newState, 3, -99999, 99999, false);
      if (value > bestValue) {
        bestValue = value;
        bestMove = move;
      }
    }
    return bestMove ?? _getRandomMove(gameState);
  }

  int _minimax(GameState gameState, int depth, int alpha, int beta, bool isMaximizingPlayer) {
    if (depth == 0 || gameState.isWinByCapture() || gameState.isWinByTemple(0, 0, PlayerColor.red) || gameState.isWinByTemple(0, 0, PlayerColor.blue)) {
      return _evaluateBoard(gameState);
    }

    if (isMaximizingPlayer) {
      int maxEval = -99999;
      final moves = _getAllPossibleMoves(gameState);
      for (final move in moves) {
        final newState = gameState.copy();
        _applyMove(newState, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) {
          break;
        }
      }
      return maxEval;
    } else {
      int minEval = 99999;
      final moves = _getAllPossibleMoves(gameState);
      for (final move in moves) {
        final newState = gameState.copy();
        _applyMove(newState, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) {
          break;
        }
      }
      return minEval;
    }
  }

  int _evaluateBoard(GameState gameState) {
    int score = 0;
    for (int r = 0; r < GameState.size; r++) {
      for (int c = 0; c < GameState.size; c++) {
        final piece = gameState.board[r][c];
        if (piece != null) {
          if (piece.owner == PlayerColor.blue) {
            score += _getPieceValue(piece, r, c);
          } else {
            score -= _getPieceValue(piece, r, c);
          }
        }
      }
    }
    return score;
  }

  int _getPieceValue(Piece piece, int r, int c) {
    int value = 0;
    if (piece.type == PieceType.master) {
      value = 1000;
    } else {
      value = 100;
    }
    // Add positional value
    if (piece.owner == PlayerColor.blue) {
      value += (GameState.size - 1 - r) * 5; // Closer to opponent's temple
      value += ((GameState.size - 1) / 2 - c).abs().toInt() * 2; // Closer to center
    } else {
      value += r * 5; // Closer to opponent's temple
      value += ((GameState.size - 1) / 2 - c).abs().toInt() * 2; // Closer to center
    }
    return value;
  }

  void _applyMove(GameState gameState, Move move) {
    final moving = gameState.board[move.from.r][move.from.c];
    gameState.board[move.to.r][move.to.c] = moving;
    gameState.board[move.from.r][move.from.c] = null;
    gameState.swapCardWithReserve(move.card);
    gameState.currentPlayer = gameState.opponent(gameState.currentPlayer);
  }

  List<Move> _getAllPossibleMoves(GameState gameState) {
    final List<Move> moves = [];
    final player = gameState.currentPlayer;
    final hand = player == PlayerColor.red ? gameState.redHand : gameState.blueHand;

    for (int r = 0; r < GameState.size; r++) {
      for (int c = 0; c < GameState.size; c++) {
        final piece = gameState.board[r][c];
        if (piece != null && piece.owner == player) {
          for (final card in hand) {
            final availableMoves = gameState.availableMovesForCell(r, c, card, player);
            for (final move in availableMoves) {
              moves.add(Move(Point(r, c), move, card));
            }
          }
        }
      }
    }
    return moves;
  }
}
