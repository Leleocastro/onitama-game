import 'package:flutter/material.dart';

import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;

  const PieceWidget({required this.piece, super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: piece.owner == PlayerColor.red ? Colors.red : Colors.blue,
      child: Icon(piece.type == PieceType.master ? Icons.castle : Icons.shield, color: Colors.white, size: 24),

      //  Text(
      //   piece.type == PieceType.master ? 'M' : 'S',
      //   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      // ),
    );
  }
}
