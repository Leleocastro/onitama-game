import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/player.dart';
import '../models/piece_type.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;

  const PieceWidget({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: piece.owner == PlayerColor.red ? Colors.red : Colors.blue,
      child: Text(
        piece.type == PieceType.master ? 'M' : 'S',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}