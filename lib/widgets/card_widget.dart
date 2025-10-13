import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/point.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final bool isSelected;
  final bool selectable;
  final Function(CardModel)? onTap;
  final bool invert;

  const CardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.selectable = true,
    this.onTap,
    this.invert = false,
  });

  @override
  Widget build(BuildContext context) {
    final moves = invert ? _invertMoves(card.moves) : card.moves;

    return GestureDetector(
      onTap: selectable ? () => onTap?.call(card) : null,
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: card.color.withOpacity(0.12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.black12,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildMovesMiniGrid(moves),
          ],
        ),
      ),
    );
  }

  Widget _buildMovesMiniGrid(List<Point> moves) {
    List<Widget> cells = [];
    for (int rr = -2; rr <= 2; rr++) {
      for (int cc = -2; cc <= 2; cc++) {
        bool hasMove = moves.any((m) => m.r == rr && m.c == cc);
        bool isCenter = rr == 0 && cc == 0;
        cells.add(
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              color: hasMove
                  ? Colors.black26
                  : isCenter
                      ? Colors.red
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    }
    return Wrap(spacing: 0, runSpacing: 0, children: cells);
  }

  List<Point> _invertMoves(List<Point> moves) {
    return moves.map((m) => Point((m.r * -1), (m.c * -1))).toList();
  }
}
