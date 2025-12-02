import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/push_notification_service.dart';
import '../utils/extensions.dart';
import '../widgets/input_text.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showUsernameInput = false;
  String? _uid;
  String? _usernameError;
  String? _authStatus;
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

  Future<void> _signInWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _authStatus = 'Informe e-mail e senha.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _authStatus = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      _uid = cred.user?.uid;
      await _checkUsername();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _authStatus = _describeAuthError(e);
      });
    } catch (e) {
      debugPrint('Erro ao fazer login com email/senha: $e');
      setState(() {
        _authStatus = 'Não foi possível entrar. Tente novamente.';
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _openRegisterScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (created == true) {
      setState(() {
        _authStatus = 'Conta criada! Faça login ou continue.';
      });
      _uid = FirebaseAuth.instance.currentUser?.uid;
      await _checkUsername();
    }
  }

  Future<void> _openForgotPasswordScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  String _describeAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Conta desativada.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      default:
        return 'Erro de autenticação (${e.code}).';
    }
  }

  Future<void> _checkUsername() async {
    if (_uid == null) return;
    setState(() {
      _isLoading = true;
    });
    final username = await _firestoreService.getUsername(_uid!);
    await _syncPhotoFromAuthUser();
    await _syncFcmToken();
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

  Future<void> _syncPhotoFromAuthUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestoreService.ensureUserPhoto(user);
    } catch (error) {
      debugPrint('Failed to sync user photo: $error');
    }
  }

  Future<void> _syncFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await PushNotificationService.getToken();
      if (token != null && token.isNotEmpty) {
        final locale = Localizations.maybeLocaleOf(context);
        await _firestoreService.updateUserFcmToken(
          user.uid,
          token,
          locale: locale,
        );
      }
    } catch (error) {
      debugPrint('Failed to sync FCM token: $error');
    }
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    // Validate: only letters (upper/lower) and numbers, no spaces/specials, max 48 chars
    final validRe = RegExp(r'^[A-Za-z0-9]{1,48}$');
    if (_uid != null && username.isNotEmpty) {
      if (!validRe.hasMatch(username)) {
        setState(() {
          _usernameError = 'Apenas letras e números (máx. 48 caracteres), sem espaços.';
        });
        return;
      }
      // clear previous error
      setState(() {
        _usernameError = null;
      });
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
      appBar: AppBar(title: Text(l10n.login, style: TextStyle(fontFamily: 'SpellOfAsia'))),
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
                        child: InputText(
                          controller: _usernameController,
                          labelText: l10n.username,
                          errorText: _usernameError ?? '',
                          maxLength: 48,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(48),
                          ],
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InputText(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          labelText: 'Email',
                          hint: 'seu@email.com',
                        ),
                        const SizedBox(height: 16),
                        InputText(
                          controller: _passwordController,
                          labelText: 'Senha',
                          hint: '•••••••',
                          isPassword: true,
                        ),
                        if (_authStatus != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _authStatus!,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _signInWithEmailPassword,
                            child: const Text('Entrar'),
                          ),
                        ),
                        TextButton(
                          onPressed: _openForgotPasswordScreen,
                          child: const Text('Esqueci minha senha'),
                        ),
                        TextButton(
                          onPressed: _openRegisterScreen,
                          child: const Text('Criar conta'),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: const [
                            Expanded(
                              child: Divider(
                                indent: 8,
                                endIndent: 8,
                                color: Colors.black12,
                              ),
                            ),
                            Text('OU'),
                            Expanded(
                              child: Divider(
                                indent: 8,
                                endIndent: 8,
                                color: Colors.black12,
                              ),
                            ),
                          ],
                        ),
                        10.0.spaceY,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _signInWithGoogle,
                              icon: Image.asset('assets/icons/google.png', width: 30, height: 30),
                            ),
                            20.0.spaceX,
                            IconButton(
                              onPressed: _signInWithApple,
                              icon: Icon(Icons.apple, size: 34),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
