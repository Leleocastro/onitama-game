import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class ProfileModal extends StatelessWidget {
  final User user;

  const ProfileModal({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.profile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${l10n.email}: ${user.email ?? 'N/A'}'),
          Text('${l10n.displayName}: ${user.displayName ?? 'N/A'}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context); // Close the modal
              }
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
