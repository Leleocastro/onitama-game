import './piece_type.dart';
import './player.dart';

class Piece {
  final PlayerColor owner;
  final PieceType type;
  final String? id; // optional id to uniquely identify a piece (useful for themed student images)

  Piece(this.owner, this.type, {this.id});
}
