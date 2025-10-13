import 'package:flutter/material.dart';
import '../logic/game_state.dart';

import '../models/point.dart';
import './piece_widget.dart';

class BoardWidget extends StatelessWidget {
  final GameState gameState;
  final Function(int, int) onCellTap;

  const BoardWidget({super.key, required this.gameState, required this.onCellTap});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(width: 2)),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: GameState.size),
          itemCount: GameState.size * GameState.size,
          itemBuilder: (context, index) {
            int r = index ~/ GameState.size;
            int c = index % GameState.size;
            final piece = gameState.board[r][c];
            final isSelected =
                gameState.selectedCell != null && gameState.selectedCell!.r == r && gameState.selectedCell!.c == c;

            List<Point> highlights = [];
            if (gameState.selectedCell != null && gameState.selectedCardForMove != null) {
              highlights = gameState.availableMovesForCell(gameState.selectedCell!.r,
                  gameState.selectedCell!.c, gameState.selectedCardForMove!, gameState.currentPlayer);
            }
            bool isHighlighted = highlights.any((p) => p.r == r && p.c == c);

            return GestureDetector(
              onTap: () => onCellTap(r, c),
              child: Container(
                margin: const EdgeInsets.all(1),
                color: (r + c) % 2 == 0
                    ? Colors.grey.shade200
                    : Colors.grey.shade300,
                child: Stack(
                  children: [
                    if (isHighlighted)
                      Positioned.fill(
                          child: Container(color: Colors.yellow.withOpacity(0.35))),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(width: 3, color: Colors.greenAccent)),
                        ),
                      ),
                    Center(child: piece == null ? const SizedBox() : PieceWidget(piece: piece)),
                    if ((r == 0 && c == 2) || (r == 4 && c == 2))
                      const Positioned(
                          top: 4, left: 4, child: Icon(Icons.location_on, size: 14, color: Colors.black26)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
