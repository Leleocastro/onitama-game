import '../models/card_model.dart';
import '../models/point.dart';

class Move {
  final Point from;
  final Point to;
  final CardModel card;

  Move(this.from, this.to, this.card);
}
