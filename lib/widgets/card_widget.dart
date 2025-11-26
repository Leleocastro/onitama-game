import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/point.dart';
import '../services/theme_manager.dart';
import '../utils/extensions.dart';

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
    this.isReserve = false,
  });

  @override
  Widget build(BuildContext context) {
    final moves = invert ? _invertMoves(card.moves) : card.moves;
    final headerColor = _darken(color, 0.2);
    final detailsColor = Color(0xFFd2be8f);
    final image = ThemeManager.cachedImage('default-card${card.name}');

    return GestureDetector(
      onTap: selectable ? () => onTap?.call(card) : null,
      child: Container(
        width: isReserve ? 70 : 85,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          image: image != null
              ? DecorationImage(
                  image: image,
                  fit: BoxFit.cover,
                  opacity: 0.4,
                )
              : null,
          color: Colors.black,
          border: Border.all(color: isSelected ? color : detailsColor),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
                border: Border(
                  bottom: BorderSide(color: detailsColor),
                  left: BorderSide(color: detailsColor),
                  right: BorderSide(color: detailsColor),
                ),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: Text(
                localizedName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isReserve ? 10 : 12,
                  fontFamily: 'SpellOfAsia',
                  color: Color(0xFFd2be8f),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            10.0.spaceY,
            Container(
              alignment: Alignment.center,
              width: isReserve ? 50 : 60,
              child: _buildMovesMiniGrid(moves, isReserve: isReserve),
            ),
            10.0.spaceY,
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
            width: isReserve ? 8 : 10,
            height: isReserve ? 8 : 10,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xAAd2be8f)),
              color: hasMove
                  ? color
                  : isCenter
                      ? Colors.white
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

  Color _darken(Color base, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(base);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
