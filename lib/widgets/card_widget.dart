import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/point.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final String localizedName;
  final bool isSelected;
  final bool selectable;
  final Function(CardModel)? onTap;
  final bool invert;
  final Color color;
  final bool isReserve;

  const CardWidget({
    required this.card,
    required this.localizedName,
    required this.color,
    super.key,
    this.isSelected = false,
    this.selectable = true,
    this.onTap,
    this.invert = false,
    this.isReserve = true,
  });

  @override
  Widget build(BuildContext context) {
    final moves = invert ? _invertMoves(card.moves) : card.moves;

    return GestureDetector(
      onTap: selectable ? () => onTap?.call(card) : null,
      child: Container(
        width: isReserve ? 80 : 110,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSelected ? Colors.green : Colors.black12),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizedName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isReserve ? 12 : 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isReserve ? 4 : 6),
            _buildMovesMiniGrid(moves, isReserve: isReserve),
          ],
        ),
      ),
    );
  }

  Widget _buildMovesMiniGrid(List<Point> moves, {bool isReserve = false}) {
    final cells = <Widget>[];
    for (var rr = -2; rr <= 2; rr++) {
      for (var cc = -2; cc <= 2; cc++) {
        final hasMove = moves.any((m) => m.r == rr && m.c == cc);
        final isCenter = rr == 0 && cc == 0;
        cells.add(
          Container(
            width: isReserve ? 10 : 14,
            height: isReserve ? 10 : 14,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              color: hasMove
                  ? color
                  : isCenter
                      ? Colors.black54
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    }
    return Wrap(children: cells);
  }

  List<Point> _invertMoves(List<Point> moves) {
    return moves.map((m) => Point((m.r * -1), (m.c * -1))).toList();
  }
}
