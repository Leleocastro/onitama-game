import 'package:flutter/material.dart';

import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../services/theme_manager.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;

  const PieceWidget({required this.piece, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.themes.values.first;
    String? imageUrl;
    if (piece.type == PieceType.master) {
      imageUrl = ThemeManager.assetUrl(piece.owner == PlayerColor.red ? 'master_red' : 'master_blue');
    } else {
      // Estudante: cada peça tem id única
      imageUrl = ThemeManager.assetUrl(piece.id ?? (piece.owner == PlayerColor.red ? 'student_red' : 'student_blue'));
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.network(imageUrl, fit: BoxFit.cover, width: 40, height: 40, errorBuilder: (c, e, s) => const Icon(Icons.error)),
        ),
      );
    }
    // fallback visual
    return CircleAvatar(
      radius: 20,
      backgroundColor: piece.owner == PlayerColor.red ? Colors.red : Colors.blue,
      child: Icon(piece.type == PieceType.master ? Icons.castle : Icons.shield, color: Colors.white, size: 24),
    );
  }
}
