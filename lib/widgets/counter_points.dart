import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CounterPoints extends StatefulWidget {
  const CounterPoints({
    required this.value,
    this.color,
    this.upWidget,
    this.leftWidget,
    this.bottomWidget,
    this.durationToStart = Duration.zero,
    this.fontWeight = FontWeight.w900,
    this.fontSize = 89,
    this.centerValue = true,
    super.key,
  });
  final int value;
  final Widget? upWidget;
  final Widget? leftWidget;
  final Widget? bottomWidget;
  final FontWeight fontWeight;
  final double fontSize;
  final Color? color;
  final Duration durationToStart;
  final bool centerValue;

  @override
  State<CounterPoints> createState() => _CounterPointsState();
}

class _CounterPointsState extends State<CounterPoints> {
  int _counter = 0;
  Timer? _timer;

  @override
  void initState() {
    Future<void>.delayed(widget.durationToStart).then((value) {
      if (widget.value > 0) {
        _timer = Timer.periodic(
          Duration(
            milliseconds: widget.value <= 2
                ? 250
                : widget.value > 1000
                    ? 1
                    : (1000 ~/ widget.value),
          ),
          (timer) {
            setState(() {
              _counter++;
            });
            if (_counter == widget.value) {
              _timer?.cancel();
            }
          },
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.upWidget != null) widget.upWidget!,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.leftWidget != null) widget.leftWidget!,
            Text(
              '$_counter',
              style: GoogleFonts.onest(
                fontWeight: widget.fontWeight,
                fontSize: widget.fontSize,
                color: widget.color,
              ),
            ),
            if (widget.centerValue)
              Opacity(
                opacity: 0,
                child: widget.leftWidget,
              ),
          ],
        ),
        if (widget.bottomWidget != null) widget.bottomWidget!,
      ],
    );
  }

  @override
  void dispose() {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    super.dispose();
  }
}
