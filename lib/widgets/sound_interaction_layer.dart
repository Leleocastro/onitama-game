import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/audio_service.dart';

/// Wraps the entire app to trigger interaction sound effects on every tap/click.
class SoundInteractionLayer extends StatelessWidget {
  const SoundInteractionLayer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (_shouldTriggerFx(event)) {
          unawaited(AudioService.instance.playUiSelectSound());
        }
      },
      child: child,
    );
  }

  bool _shouldTriggerFx(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      return event.buttons != 0;
    }
    return true;
  }
}
