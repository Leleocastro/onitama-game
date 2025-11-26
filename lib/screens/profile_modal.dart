import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../utils/extensions.dart';
import '../widgets/username_avatar.dart';

class ProfileModal extends StatelessWidget {
  final User user;
  final String username;

  const ProfileModal({required this.user, required this.username, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.profile, style: TextStyle(fontFamily: 'SpellOfAsia')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UsernameAvatar(username: username, size: 50),
          Text(
            username,
            textAlign: TextAlign.center,
            style: GoogleFonts.onest(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          10.0.spaceY,
          Text('${l10n.email}: ${user.email ?? 'N/A'}', style: GoogleFonts.onest()),
          Text('${l10n.displayName}: ${user.displayName ?? 'N/A'}', style: GoogleFonts.onest()),
          10.0.spaceY,
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context); // Close the modal
              }
            },
            child: Text(l10n.signOut, style: GoogleFonts.onest(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
