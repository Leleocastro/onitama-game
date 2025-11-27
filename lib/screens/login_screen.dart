import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/push_notification_service.dart';
import '../utils/extensions.dart';
import '../widgets/input_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  AppLinks? _appLinks;
  bool _showUsernameInput = false;
  String? _uid;
  String? _usernameError;
  String? _emailStatus;
  bool _isLoading = false;
  StreamSubscription<Uri?>? _sub;

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

  Future<void> _sendSignInLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailStatus = 'Informe um e-mail válido.';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://onitama-game.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'com.ltag.onitama',
        androidInstallApp: true,
        iOSBundleId: 'com.ltag.onitama',
      );

      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // Store email locally to complete sign-in when the link is opened
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email_for_signin', email);
      } catch (e) {
        debugPrint('Could not save email to prefs: $e');
      }

      setState(() {
        _emailStatus = 'Link de login enviado para $email. Verifique seu e-mail.';
      });
    } catch (e) {
      debugPrint('Erro ao enviar link de login por email: $e');
      setState(() {
        _emailStatus = 'Erro ao enviar link. Tente novamente.';
      });
    }
    setState(() => _isLoading = false);
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
        await _firestoreService.updateUserFcmToken(user.uid, token);
      }
    } catch (error) {
      debugPrint('Failed to sync FCM token: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    // Inicializa escuta de deep links para completar o sign-in por email
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    try {
      _appLinks = AppLinks();
      final initialUri = await _appLinks!.getInitialLink();
      await _handleIncomingLink(initialUri!);

      _sub = _appLinks!.uriLinkStream.listen(
        (uri) {
          _handleIncomingLink(uri);
        },
        onError: (err) {
          debugPrint('Erro no uriLinkStream: $err');
        },
      );
    } catch (e) {
      debugPrint('Erro ao inicializar AppLinks: $e');
    }
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    final link = uri.toString();
    debugPrint('Incoming link: $link');
    try {
      final auth = FirebaseAuth.instance;
      if (auth.isSignInWithEmailLink(link)) {
        setState(() => _isLoading = true);

        // tenta recuperar email salvo
        String? email;
        try {
          final prefs = await SharedPreferences.getInstance();
          email = prefs.getString('email_for_signin');
        } catch (e) {
          debugPrint('Erro ao ler SharedPreferences: $e');
        }

        // se não tivermos o email salvo, peça para o usuário digitar
        if (email == null || email.isEmpty) {
          email = await showDialog<String?>(
            context: context,
            builder: (ctx) {
              final ctrl = TextEditingController();
              return AlertDialog(
                title: const Text('Confirme seu e-mail'),
                content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Seu e-mail usado no pedido do link'),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: const Text('OK')),
                ],
              );
            },
          );
        }

        if (email == null || email.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }

        try {
          final userCred = await auth.signInWithEmailLink(email: email, emailLink: link);
          _uid = userCred.user?.uid;
          // remove o email salvo
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('email_for_signin');
          } catch (e) {
            debugPrint('Erro ao remover email das prefs: $e');
          }

          await _checkUsername();
        } catch (e) {
          debugPrint('Erro ao completar signInWithEmailLink: $e');
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erro ao tratar incoming link: $e');
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
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: InputText(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hint: 'Email',
                        ),
                      ),
                      if (_emailStatus != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            _emailStatus!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _sendSignInLink,
                        child: const Text('Entrar com email'),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              indent: 32,
                              endIndent: 8,
                              color: Colors.black12,
                            ),
                          ),
                          Text('OU'),
                          Expanded(
                            child: Divider(
                              indent: 8,
                              endIndent: 32,
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
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
