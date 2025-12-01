import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/move.dart';
import '../models/player.dart';
import '../widgets/card_widget.dart';

class HistoricGameDetailScreen extends StatelessWidget {
  final List<Move> moves;

  const HistoricGameDetailScreen({required this.moves, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moveHistoryTitle, style: TextStyle(fontFamily: 'SpellOfAsia')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: moves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final move = moves[index];
          final isBlueTurn = index.isEven;
          final playerColor = isBlueTurn ? PlayerColor.blue : PlayerColor.red;
          final accentColor = isBlueTurn ? Colors.indigo.shade500 : Colors.red.shade400;
          final moveTitle = '${l10n.moveHistoryMove(index + 1)} • ${isBlueTurn ? l10n.blue : l10n.red}';
          final moveSubtitle = l10n.moveHistoryFromTo(move.card.name, move.from.c, move.from.r, move.to.c, move.to.r);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moveTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MovePreviewBoard(
                          move: move,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 110,
                        child: CardWidget(
                          card: move.card,
                          localizedName: _getLocalizedCardName(context, move.card.name),
                          color: accentColor,
                          isReserve: true,
                          invert: playerColor == PlayerColor.blue,
                          selectable: false,
                          move: (index + 1).toString(),
                          owner: playerColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    moveSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getLocalizedCardName(BuildContext context, String cardName) {
    final l10n = AppLocalizations.of(context)!;
    switch (cardName) {
      case 'Tiger':
        return l10n.cardTiger;
      case 'Dragon':
        return l10n.cardDragon;
      case 'Frog':
        return l10n.cardFrog;
      case 'Rabbit':
        return l10n.cardRabbit;
      case 'Crab':
        return l10n.cardCrab;
      case 'Elephant':
        return l10n.cardElephant;
      case 'Goose':
        return l10n.cardGoose;
      case 'Rooster':
        return l10n.cardRooster;
      case 'Monkey':
        return l10n.cardMonkey;
      case 'Mantis':
        return l10n.cardMantis;
      case 'Horse':
        return l10n.cardHorse;
      case 'Ox':
        return l10n.cardOx;
      case 'Crane':
        return l10n.cardCrane;
      case 'Boar':
        return l10n.cardBoar;
      case 'Eel':
        return l10n.cardEel;
      case 'Cobra':
        return l10n.cardCobra;
      default:
        return cardName;
    }
  }
}

class _MovePreviewBoard extends StatelessWidget {
  const _MovePreviewBoard({required this.move, required this.color});

  final Move move;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _MovePreviewPainter(move: move, color: color, background: Theme.of(context).colorScheme.surfaceContainerHighest),
        ),
      ),
    );
  }
}

class _MovePreviewPainter extends CustomPainter {
  _MovePreviewPainter({required this.move, required this.color, required this.background});

  final Move move;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 5;
    final boardLight = Paint()..color = background.withOpacity(0.9);
    final boardDark = Paint()..color = background.withOpacity(0.6);
    final gridPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke;

    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, (r + c) % 2 == 0 ? boardLight : boardDark);
        canvas.drawRect(rect, gridPaint);
      }
    }

    final fromCenter = Offset((move.from.c + 0.5) * cellSize, (move.from.r + 0.5) * cellSize);
    final toCenter = Offset((move.to.c + 0.5) * cellSize, (move.to.r + 0.5) * cellSize);

    final linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = cellSize * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(fromCenter, toCenter, linePaint);

    _drawArrowHead(canvas, fromCenter, toCenter, linePaint.strokeWidth);

    final fromPaint = Paint()..color = color;
    final toPaint = Paint()..color = color.withOpacity(0.45);
    final radius = cellSize * 0.3;
    canvas.drawCircle(fromCenter, radius, fromPaint);
    canvas.drawCircle(toCenter, radius, toPaint);
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, double strokeWidth) {
    final direction = (to - from);
    final angle = math.atan2(direction.dy, direction.dx);
    final arrowLength = strokeWidth * 4;
    final arrowAngle = math.pi / 6;
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowLength * math.cos(angle - arrowAngle),
        to.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..lineTo(
        to.dx - arrowLength * math.cos(angle + arrowAngle),
        to.dy - arrowLength * math.sin(angle + arrowAngle),
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
