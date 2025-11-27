import 'package:flutter/material.dart';

import '../utils/extensions.dart';

class MoveDownWidget extends StatefulWidget {
  const MoveDownWidget({
    required this.child,
    this.moveDown,
    this.height,
    super.key,
  });
  final Widget child;
  final bool? moveDown;
  final double? height;

  @override
  State<MoveDownWidget> createState() => _MoveDownWidgetState();
}

class _MoveDownWidgetState extends State<MoveDownWidget> {
  final duration = const Duration(milliseconds: 500);
  bool moveDown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        moveDown = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      height: widget.height ?? (context.height / 6),
      alignment: (widget.moveDown ?? moveDown) ? Alignment.bottomCenter : Alignment.topCenter,
      child: widget.child,
    );
  }
}
