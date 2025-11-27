import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foil/foil.dart';

import '../models/card_model.dart';
import '../models/point.dart';
import '../services/theme_manager.dart';
import '../utils/extensions.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final String localizedName;
  final bool isSelected;
  final bool selectable;
  final Function(CardModel)? onTap;
  final bool invert;
  final Color color;
  final bool isReserve;
  final bool canTap;

  const CardWidget({
    required this.card,
    required this.localizedName,
    required this.color,
    super.key,
    this.isSelected = false,
    this.selectable = true,
    this.onTap,
    this.invert = false,
    this.isReserve = false,
    this.canTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final moves = invert ? _invertMoves(card.moves) : card.moves;
    final headerColor = _darken(color, 0.2);
    const detailsColor = Color(0xFFd2be8f);
    final image = ThemeManager.cachedImage('default-card${card.name}');
    final heroTag = 'cardTexture-${card.name}-${isReserve ? 'reserve' : 'board'}';

    return GestureDetector(
      onTap: selectable
          ? canTap
              ? () => onTap?.call(card)
              : null
          : () {
              Navigator.of(context).push(
                _HeroDialogRoute(
                  builder: (ctx) => _CardOpened(
                    title: localizedName,
                    image: image,
                    heroTag: heroTag,
                    color: color,
                    moves: _invertMoves(card.moves),
                  ),
                ),
              );
            },
      onLongPress: () {
        Navigator.of(context).push(
          _HeroDialogRoute(
            builder: (ctx) => _CardOpened(
              title: localizedName,
              image: image,
              heroTag: heroTag,
              color: color,
              moves: _invertMoves(card.moves),
            ),
          ),
        );
      },
      child: Container(
        width: isReserve ? 75 : 85,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: isSelected ? color : detailsColor),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: Stack(
          children: [
            if (image != null)
              Positioned.fill(
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        isSelected ? color.withOpacity(0.4) : Colors.black.withOpacity(0.45),
                        BlendMode.srcATop,
                      ),
                      child: Image(
                        image: image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                    border: Border(
                      bottom: const BorderSide(color: detailsColor),
                      left: const BorderSide(color: detailsColor),
                      right: const BorderSide(color: detailsColor),
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    localizedName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isReserve ? 10 : 12,
                      fontFamily: 'SpellOfAsia',
                      color: detailsColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                10.0.spaceY,
                Container(
                  alignment: Alignment.center,
                  width: isReserve ? 50 : 60,
                  child: _buildMovesMiniGrid(moves, isReserve: isReserve, color: color),
                ),
                10.0.spaceY,
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Point> _invertMoves(List<Point> moves) {
    return moves.map((m) => Point((m.r * -1), (m.c * -1))).toList();
  }
}

Widget _buildMovesMiniGrid(
  List<Point> moves, {
  required Color color,
  bool isReserve = false,
}) {
  final cells = <Widget>[];
  for (var rr = -2; rr <= 2; rr++) {
    for (var cc = -2; cc <= 2; cc++) {
      final hasMove = moves.any((m) => m.r == rr && m.c == cc);
      final isCenter = rr == 0 && cc == 0;
      cells.add(
        Container(
          width: isReserve ? 8 : 10,
          height: isReserve ? 8 : 10,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xAAd2be8f)),
            color: hasMove
                ? color
                : isCenter
                    ? Colors.white54
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
  }
  return Wrap(children: cells);
}

Color _darken(Color base, [double amount = 0.1]) {
  final hsl = HSLColor.fromColor(base);
  final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

const _foilAnimationSpeed = Duration(milliseconds: 30);

LinearGradient _foilGradient(Color sparkleColor) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.white.withOpacity(0.05),
      sparkleColor.withOpacity(0.35),
      const Color(0xFF7C4DFF).withOpacity(0.25),
      Colors.white.withOpacity(0.1),
      Colors.transparent,
    ],
    stops: const [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
  );
}

class _CardOpened extends StatelessWidget {
  const _CardOpened({
    required this.title,
    required this.image,
    required this.heroTag,
    required this.color,
    required this.moves,
  });
  final String title;
  final CachedNetworkImageProvider? image;
  final String heroTag;
  final Color color;
  final List<Point> moves;

  @override
  Widget build(BuildContext context) {
    const detailsColor = Color(0xFFd2be8f);

    return GestureDetector(
      onTap: Navigator.of(context).pop,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                children: [
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Foil(
                        gradient: _foilGradient(color),
                        blendMode: BlendMode.screen,
                        speed: _foilAnimationSpeed,
                        child: Foil(
                          gradient: Foils.sitAndSpin,
                          opacity: 0.05,
                          isAgressive: true,
                          scalar: Scalar(horizontal: 15, vertical: 15),
                          child: _OrnateFrame(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (image != null)
                                  Image(
                                    image: image!,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(color: Colors.white),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 18),
                                    child: _TitlePlaque(
                                      text: title,
                                      color: _darken(color),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          _darken(color),
                                          _darken(color),
                                          _darken(color).withOpacity(0.95),
                                          _darken(color).withOpacity(0.9),
                                          _darken(color).withOpacity(0.7),
                                          _darken(color).withOpacity(0.4),
                                          _darken(color).withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        20.0.spaceY,
                                        Text(
                                          'Inteligente e brincalhão, ele explora a vida com curiosidade.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'SpellOfAsia',
                                            color: detailsColor,
                                            fontSize: 16,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        10.0.spaceY,
                                        SizedBox(
                                          width: 50,
                                          child: _buildMovesMiniGrid(
                                            moves,
                                            color: color,
                                            isReserve: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroDialogRoute extends PageRoute<void> {
  _HeroDialogRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'card-preview';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );
  }
}

class _OrnateFrame extends StatelessWidget {
  const _OrnateFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
            const _CornerFiligreeOverlay(),
          ],
        ),
      ),
    );
  }
}

class _CornerFiligreeOverlay extends StatelessWidget {
  const _CornerFiligreeOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          _CornerOrnament(alignment: Alignment.topLeft),
          _CornerOrnament(alignment: Alignment.topRight, flipX: true),
          _CornerOrnament(alignment: Alignment.bottomLeft, flipY: true),
          _CornerOrnament(alignment: Alignment.bottomRight, flipX: true, flipY: true),
        ],
      ),
    );
  }
}

class _CornerOrnament extends StatelessWidget {
  const _CornerOrnament({required this.alignment, this.flipX = false, this.flipY = false});

  final Alignment alignment;
  final bool flipX;
  final bool flipY;

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);

    return Align(
      alignment: alignment,
      child: Transform(
        transform: matrix,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/images/corner.png',
            width: 70,
            height: 70,
            color: Color(0xFFd2be8f),
          ),
        ),
      ),
    );
  }
}

class _TitlePlaque extends StatelessWidget {
  const _TitlePlaque({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const detailsColor = Color(0xFFd2be8f);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: ShapeDecoration(
        color: color,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: detailsColor),
        ),
        shadows: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'SpellOfAsia',
          color: detailsColor,
          fontSize: 22,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
