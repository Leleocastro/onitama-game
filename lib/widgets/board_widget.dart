import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../models/move.dart';
import '../models/player.dart';
import '../models/point.dart';
import '../services/theme_manager.dart';
import './piece_widget.dart';

class BoardWidget extends StatelessWidget {
  final GameState gameState;
  final Function(int, int) onCellTap;
  final PlayerColor playerColor;

  const BoardWidget({
    required this.gameState,
    required this.onCellTap,
    super.key,
    this.playerColor = PlayerColor.blue,
  });

  @override
  Widget build(BuildContext context) {
    final isRed = playerColor == PlayerColor.red;
    final board = ThemeManager.cachedImage('default-board');
    final board0 = ThemeManager.cachedImage('default-board0');
    final board1 = ThemeManager.cachedImage('default-board1');

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          // border: Border.all(width: 2),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.1).round()),
              blurRadius: 12,
              offset: const Offset(0, 12),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
          image: board != null
              ? DecorationImage(
                  image: board,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / GameState.size;
            return Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: GameState.size),
                  itemCount: GameState.size * GameState.size,
                  itemBuilder: (context, index) {
                    final r = index ~/ GameState.size;
                    final c = index % GameState.size;
                    final displayR = isRed ? GameState.size - 1 - r : r;
                    final displayC = isRed ? GameState.size - 1 - c : c;

                    final piece = gameState.board[displayR][displayC];
                    final isSelected = gameState.selectedCell != null && gameState.selectedCell!.r == displayR && gameState.selectedCell!.c == displayC;

                    var highlights = <Point>[];
                    if (gameState.selectedCell != null && gameState.selectedCardForMove != null) {
                      highlights = gameState.availableMovesForCell(
                        gameState.selectedCell!.r,
                        gameState.selectedCell!.c,
                        gameState.selectedCardForMove!,
                        gameState.currentPlayer,
                      );
                    }
                    final isHighlighted = highlights.any((p) => p.r == displayR && p.c == displayC);

                    return GestureDetector(
                      onTap: () => onCellTap(displayR, displayC),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: (r + c) % 2 == 0 ? Colors.grey.shade200.withOpacity(0.6) : Colors.grey.shade300.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                          image: (r + c) % 2 == 0
                              ? (board0 != null ? DecorationImage(image: board0, fit: BoxFit.cover) : null)
                              : (board1 != null ? DecorationImage(image: board1, fit: BoxFit.cover) : null),
                        ),
                        child: Stack(
                          children: [
                            if (isHighlighted)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.yellow.withAlpha((255 * 0.35).round()),
                                  ),
                                ),
                              ),
                            if (isSelected)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 2, color: Colors.greenAccent),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            Center(child: piece == null ? const SizedBox() : PieceWidget(piece: piece)),
                            if ((displayR == 0 && displayC == 2) || (displayR == 4 && displayC == 2))
                              const Positioned(top: 4, left: 4, child: Icon(Icons.temple_buddhist, size: 14, color: Colors.black26)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (gameState.lastMove != null)
                  IgnorePointer(
                    child: CustomPaint(painter: ArrowPainter(gameState.lastMove!, cellSize, isRed), child: Container()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Move lastMove;
  final double cellSize;
  final bool isRed;

  ArrowPainter(this.lastMove, this.cellSize, this.isRed);

  @override
  void paint(Canvas canvas, Size size) {
    var fromR = lastMove.from.r.toDouble();
    var fromC = lastMove.from.c.toDouble();
    var toR = lastMove.to.r.toDouble();
    var toC = lastMove.to.c.toDouble();

    if (isRed) {
      fromR = GameState.size - 1 - fromR;
      fromC = GameState.size - 1 - fromC;
      toR = GameState.size - 1 - toR;
      toC = GameState.size - 1 - toC;
    }

    final p1 = Offset(fromC * cellSize + cellSize / 2, fromR * cellSize + cellSize / 2);
    final p2 = Offset(toC * cellSize + cellSize / 2, toR * cellSize + cellSize / 2);

    final paint = Paint()
      ..color = Colors.black.withAlpha((255 * 0.4).round())
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Calculate the angle and shorten the line to end before the arrow
    final angle = (p2 - p1).direction;
    final arrowLength = 15.0;
    final shortenedP2 = Offset(
      p2.dx - arrowLength * cos(angle),
      p2.dy - arrowLength * sin(angle),
    );

    canvas.drawLine(p1, shortenedP2, paint);

    // Draw arrow head
    final path = Path();
    path.moveTo(p2.dx - 15 * cos(angle - 0.5), p2.dy - 15 * sin(angle - 0.5));
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p2.dx - 15 * cos(angle + 0.5), p2.dy - 15 * sin(angle + 0.5));
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
