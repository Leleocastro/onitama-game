import './player.dart';
import './piece_type.dart';

class Piece {
  final PlayerColor owner;
  final PieceType type;
  Piece(this.owner, this.type);
}
