import 'package:flutter/material.dart';

import '../models/piece.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../services/theme_manager.dart';
import '../utils/piece_visual_utils.dart';

class PieceWidget extends StatelessWidget {
  final Piece piece;

  const PieceWidget({required this.piece, super.key});

  @override
  Widget build(BuildContext context) {
    final assetId = _assetIdForPiece(piece);
    final image = ThemeManager.themedImage(assetId, owner: piece.owner);
    final needsDesaturation = piece.owner == PlayerColor.red && _sharesTextureWithBlue(assetId);
    if (image != null) {
      Widget img = Image(
        image: image,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        errorBuilder: (c, e, s) => const Icon(Icons.error),
      );

      if (needsDesaturation) {
        img = ColorFiltered(
          colorFilter: redPieceDesaturationFilter,
          child: img,
        );
      }

      return img;
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: piece.owner == PlayerColor.red ? Colors.red : Colors.blue,
      child: Icon(piece.type == PieceType.master ? Icons.castle : Icons.shield, color: Colors.white, size: 24),
    );
  }

  String _assetIdForPiece(Piece piece) {
    if (piece.type == PieceType.master) {
      return piece.owner == PlayerColor.red ? 'master_red' : 'master_blue';
    }
    return piece.id ?? (piece.owner == PlayerColor.red ? 'r0' : 'b0');
  }

  bool _sharesTextureWithBlue(String redAssetId) {
    final counterpart = pairedPieceAssetId(redAssetId);
    if (counterpart == null) return false;
    final redUrl = ThemeManager.themedAssetUrl(redAssetId, owner: PlayerColor.red);
    final blueUrl = ThemeManager.themedAssetUrl(counterpart, owner: PlayerColor.blue);
    if (redUrl == null || blueUrl == null) return false;
    return redUrl == blueUrl;
  }
}
