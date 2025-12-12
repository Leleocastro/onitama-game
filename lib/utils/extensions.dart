import 'dart:async';

import 'package:flutter/material.dart';

extension SpaceXY on double {
  SizedBox get spaceX => SizedBox(width: this);
  SizedBox get spaceY => SizedBox(height: this);
}

extension SizeWH on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get safeAreaTopPadding => MediaQuery.of(this).padding.top;
  double get additionalTop => safeAreaTopPadding > 25 ? 25 : safeAreaTopPadding;
  double get insetsBottom => MediaQuery.of(this).viewInsets.bottom;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
}

const _toastDisplayDuration = Duration(seconds: 3);
OverlayEntry? _activeToastEntry;
Timer? _activeToastTimer;

// Renders a lightweight toast overlay that replaces the default scaffold snackbar.
void _showToast({
  required BuildContext context,
  required Color backgroundColor,
  required IconData icon,
  required String message,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  _activeToastTimer?.cancel();
  _activeToastEntry?.remove();

  final entry = OverlayEntry(
    builder: (overlayContext) {
      final mediaQuery = MediaQuery.of(overlayContext);
      final theme = Theme.of(overlayContext);
      return Positioned(
        left: 16,
        right: 16,
        bottom: 24 + mediaQuery.padding.bottom,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
    },
  );

  overlay.insert(entry);
  _activeToastEntry = entry;

  _activeToastTimer = Timer(_toastDisplayDuration, () {
    if (entry.mounted) {
      entry.remove();
    }
    if (identical(_activeToastEntry, entry)) {
      _activeToastEntry = null;
      _activeToastTimer = null;
    }
  });
}

extension ToastContext on BuildContext {
  void toToastSuccess(String message) {
    _showToast(
      context: this,
      backgroundColor: const Color(0xFF1E8F5B),
      icon: Icons.check_circle_outline,
      message: message,
    );
  }

  void toToastError(String message) {
    _showToast(
      context: this,
      backgroundColor: const Color(0xFFB3261E),
      icon: Icons.error_outline,
      message: message,
    );
  }
}
