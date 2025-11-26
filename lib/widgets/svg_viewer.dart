import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgViewer extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final Color? color;

  const SvgViewer({required this.asset, super.key, this.width = 24, this.height = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final svgColor = color;

    return SvgPicture.asset(asset, width: width, height: height, colorFilter: svgColor != null ? ColorFilter.mode(svgColor, BlendMode.srcIn) : null);
  }
}
