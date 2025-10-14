import 'package:flutter/material.dart';

import '../style/theme.dart';

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const StyledButton({required this.text, required this.onPressed, super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: AppTheme.themeData.elevatedButtonTheme.style,
        child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) Icon(icon, size: 18), if (icon != null) const SizedBox(width: 8), Text(text)]),
      ),
    );
  }
}
