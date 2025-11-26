import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../style/theme.dart';
import '../widgets/leaderboard_widget.dart';
import '../widgets/username_avatar.dart';
import 'how_to_play_screen.dart';
import 'login_screen.dart';
import 'play_menu.dart';
import 'profile_modal.dart';

class MenuScreen2 extends StatefulWidget {
  const MenuScreen2({super.key});

  @override
  State<MenuScreen2> createState() => _MenuScreen2State();
}

class _MenuScreen2State extends State<MenuScreen2> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late File file;
  late RiveWidgetController controller;
  bool isInitialized = false;
  late StreamSubscription<AccelerometerEvent> _accelSub;
  double _offsetX = 0;
  double _offsetY = 0;

  final double _maxOffset = 20;
  final double _sensitivity = 1.8;

  StreamSubscription<User?>? _authStateChangesSubscription;
  String? _playerUid;
  final Map<String, Future<String?>> _usernameFutures = <String, Future<String?>>{};

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        // Rebuild the widget when auth state changes
      });
    });
    initRive();
    // Inicia o listener do acelerômetro para mover o background
    _accelSub = accelerometerEvents.listen((event) {
      // event.x, event.y, event.z representam aceleração em m/s²
      // Aqui mapeamos a inclinação para deslocamento do background.
      // Ajustes: troca e sinais para melhor sensação conforme dispositivo.
      final rawX = event.y; // usar eixo Y para movimento horizontal
      final rawY = event.x; // usar eixo X para movimento vertical

      var targetX = rawX * _sensitivity;
      var targetY = rawY * _sensitivity;

      // Clamp para limites visuais
      if (targetX > _maxOffset) targetX = _maxOffset;
      if (targetX < -_maxOffset) targetX = -_maxOffset;
      if (targetY > _maxOffset) targetY = _maxOffset;
      if (targetY < -_maxOffset) targetY = -_maxOffset;

      setState(() {
        _offsetX = targetX;
        _offsetY = targetY;
      });
    });
  }

  Future<void> _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _playerUid = await _firestoreService.signInAnonymously();
    } else {
      _playerUid = user.uid;
    }
    setState(() {});
  }

  Future<void> initRive() async {
    file = (await File.asset('assets/rive/animated-background.riv', riveFactory: Factory.rive))!;
    controller = RiveWidgetController(file);
    setState(() => isInitialized = true);
  }

  @override
  void dispose() {
    file.dispose();
    controller.dispose();
    _accelSub.cancel();
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          if (isInitialized)
            // Aplica deslocamento baseado no acelerômetro
            Transform.translate(
              offset: Offset(_offsetX, _offsetY),
              child: RiveWidget(
                controller: controller,
                fit: Fit.cover,
              ),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 150,
                ),
              ),
              Text(
                l10n.gameOfTheMasters,
                style: GoogleFonts.pompiere(fontSize: 24, color: Colors.black),
              ),
              SizedBox(height: 20),
              Center(
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black87,
                      transitionAnimationController: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
                      isScrollControlled: true,
                      builder: (_) => PlayMenu(playerUid: _playerUid!),
                    );
                  },
                  child: Text(
                    l10n.play,
                    style: TextStyle(
                      fontFamily: 'HIROMISAKE',
                      color: AppTheme.primary,
                      fontSize: 62,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 150),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // if (user != null && !user.isAnonymous)
                  IconButton(
                    onPressed: () {
                      final playerUid = user?.uid ?? _playerUid;
                      if (playerUid == null) return;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        barrierColor: Colors.black87,
                        builder: (context) => Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.all(20),
                          child: LeaderboardWidget(playerUid: playerUid),
                        ),
                      );
                    },
                    icon: Image.asset(
                      'assets/icons/podium.png',
                      width: 36,
                    ),
                  ),
                  SizedBox(width: 5),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HowToPlayScreen(),
                        ),
                      );
                    },
                    icon: Image.asset(
                      'assets/icons/tutorials.png',
                      width: 36,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasData && snapshot.data != null && !snapshot.data!.isAnonymous) {
                    final user = snapshot.data!;
                    final usernameFuture = _usernameFutures.putIfAbsent(user.uid, () => _firestoreService.getUsername(user.uid));
                    return FutureBuilder<String?>(
                      future: usernameFuture,
                      builder: (context, usernameSnapshot) {
                        final username = usernameSnapshot.data ?? user.displayName ?? user.email ?? 'player';
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => ProfileModal(
                                  user: user,
                                  username: username,
                                ),
                              );
                            },
                            child: UsernameAvatar(
                              username: username,
                              tooltip: username,
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.login,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
