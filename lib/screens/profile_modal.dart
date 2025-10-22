
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileModal extends StatelessWidget {
  final User user;

  const ProfileModal({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Email: ${user.email ?? 'N/A'}'),
          Text('Display Name: ${user.displayName ?? 'N/A'}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pop(context); // Close the modal
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
