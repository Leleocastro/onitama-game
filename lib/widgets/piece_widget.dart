import 'package:cached_network_image/cached_network_image.dart';
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
    CachedNetworkImageProvider? image;
    if (piece.type == PieceType.master) {
      image = ThemeManager.themedImage(piece.owner == PlayerColor.red ? 'master_red' : 'master_blue');
    } else {
      // Estudante: cada peça tem id única
      final assetId = piece.id ?? (piece.owner == PlayerColor.red ? 'r0' : 'b0');
      image = ThemeManager.themedImage(assetId);
    }
    if (image != null) {
      final img = Image(
        image: image,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        errorBuilder: (c, e, s) => const Icon(Icons.error),
      );

      return img;
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: piece.owner == PlayerColor.red ? Colors.red : Colors.blue,
      child: Icon(piece.type == PieceType.master ? Icons.castle : Icons.shield, color: Colors.white, size: 24),
    );
  }
}
