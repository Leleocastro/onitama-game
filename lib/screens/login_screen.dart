import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _usernameController = TextEditingController();
  bool _showUsernameInput = false;
  String? _uid;
  String? _usernameError;
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final googleProvider = GoogleAuthProvider();
      final credential = await FirebaseAuth.instance.signInWithProvider(googleProvider);
      _uid = credential.user?.uid;
      await _checkUsername();
    } catch (e) {
      debugPrint('Google sign-in error: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final appleProvider = AppleAuthProvider();
      final credential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      _uid = credential.user?.uid;
      await _checkUsername();
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkUsername() async {
    if (_uid == null) return;
    setState(() {
      _isLoading = true;
    });
    final username = await _firestoreService.getUsername(_uid!);
    setState(() {
      _isLoading = false;
    });
    if (username == null || username.isEmpty) {
      setState(() {
        _showUsernameInput = true;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (_uid != null && username.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      final exists = await _firestoreService.usernameExists(username);
      setState(() {
        _isLoading = false;
      });
      if (exists) {
        setState(() {
          _usernameError = AppLocalizations.of(context)!.usernameAlreadyExists;
        });
        return;
      }
      setState(() {
        _isLoading = true;
      });
      await _firestoreService.setUsername(_uid!, username);
      setState(() {
        _showUsernameInput = false;
        _usernameError = null;
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _showUsernameInput
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.chooseUsername),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: l10n.username,
                            errorText: _usernameError,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _saveUsername,
                        icon: const Icon(Icons.save),
                        label: Text(l10n.save),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: Text(l10n.signInWithGoogle),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _signInWithApple,
                        icon: const Icon(Icons.apple),
                        label: Text(l10n.signInWithApple),
                      ),
                    ],
                  ),
      ),
    );
  }
}
