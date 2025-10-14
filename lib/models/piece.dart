import './piece_type.dart';
import './player.dart';

class Piece {
  final PlayerColor owner;
  final PieceType type;
  Piece(this.owner, this.type);
}
