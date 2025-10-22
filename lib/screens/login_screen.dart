import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final googleProvider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithProvider(googleProvider);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final appleProvider = AppleAuthProvider();
      await FirebaseAuth.instance.signInWithProvider(appleProvider);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _signInWithGoogle(context),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _signInWithApple(context),
              icon: const Icon(Icons.apple),
              label: const Text('Sign in with Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
