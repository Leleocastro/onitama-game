import 'package:flutter/material.dart';

import '../utils/avatar_generator.dart';

/// Renders a deterministic avatar generated from a username.
class UsernameAvatar extends StatelessWidget {
  const UsernameAvatar({
    required this.username,
    this.size = 35,
    this.tooltip,
    super.key,
  });

  final String username;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final avatarSeed = AvatarGenerator.fromUsername(username);
    final avatar = RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: _AvatarPainter(avatarSeed),
            size: Size.square(size),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip, child: avatar);
    }
    return avatar;
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.seed)
      : _backgroundPaint = Paint()
          ..color = seed.backgroundColor
          ..style = PaintingStyle.fill,
        _primaryPaint = Paint()
          ..color = seed.foregroundColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

  final AvatarToken seed;
  final Paint _backgroundPaint;
  final Paint _primaryPaint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);
    final cellWidth = size.width / AvatarGenerator.gridSize;
    final cellHeight = size.height / AvatarGenerator.gridSize;
    final inset = cellWidth * 0.15;

    for (var index = 0; index < seed.pattern.length; index++) {
      if (!seed.pattern[index]) continue;
      final row = index ~/ AvatarGenerator.gridSize;
      final column = index % AvatarGenerator.gridSize;
      final rect = Rect.fromLTWH(column * cellWidth, row * cellHeight, cellWidth, cellHeight).deflate(inset);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cellWidth * 0.2)), _primaryPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) => seed != oldDelegate.seed;
}
