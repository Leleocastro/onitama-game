import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';
import '../services/route_observer.dart';
import '../services/tutorial_service.dart';
import '../style/theme.dart';
import '../widgets/gold_statement_sheet.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/username_avatar.dart';
import '../widgets/volume_settings_sheet.dart';
import 'how_to_play_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';
import 'play_menu.dart';
import 'profile_modal.dart';

class MenuScreen2 extends StatefulWidget {
  const MenuScreen2({super.key});

  @override
  State<MenuScreen2> createState() => _MenuScreen2State();
}

class _MenuScreen2State extends State<MenuScreen2> with TickerProviderStateMixin, RouteAware {
  final FirestoreService _firestoreService = FirestoreService();
  late File file;
  late RiveWidgetController controller;
  bool isInitialized = false;
  PageRoute<dynamic>? _route;

  StreamSubscription<User?>? _authStateChangesSubscription;
  String? _playerUid;
  final GlobalKey _playButtonKey = GlobalKey();
  final GlobalKey _leaderboardButtonKey = GlobalKey();
  final GlobalKey _howToPlayButtonKey = GlobalKey();
  final GlobalKey _profileButtonKey = GlobalKey();
  final GlobalKey _volumeButtonKey = GlobalKey();
  bool _menuTutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    _startMenuMusic();
    _initializeUser();
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        // Rebuild the widget when auth state changes
      });
    });
    initRive();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowMenuTutorial());
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
    _authStateChangesSubscription?.cancel();
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(covariant MenuScreen2 oldWidget) {
    _startMenuMusic();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didPush() {
    _startMenuMusic();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _startMenuMusic();
  }

  @override
  void didPop() {
    super.didPop();
    _startMenuMusic();
  }

  void _startMenuMusic() {
    unawaited(AudioService.instance.playMenuMusic());
  }

  void _openVolumeSettings() {
    unawaited(AudioService.instance.playUiConfirmSound());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const VolumeSettingsSheet(),
    );
  }

  void _openGoldStatement(String userId) {
    if (userId.isEmpty) return;
    unawaited(AudioService.instance.playUiConfirmSound());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GoldStatementSheet(userId: userId),
    );
  }

  Future<void> _maybeShowMenuTutorial() async {
    if (!mounted || _menuTutorialScheduled) {
      return;
    }
    final shouldShow = await TutorialService.shouldShow(TutorialFlow.menu);
    if (!shouldShow || !mounted) {
      return;
    }
    _menuTutorialScheduled = true;
    const attempts = 6;
    var ready = _areMenuTargetsReady();
    var tries = 0;
    while (!ready && tries < attempts && mounted) {
      await Future.delayed(const Duration(milliseconds: 150));
      ready = _areMenuTargetsReady();
      tries++;
    }
    if (!ready || !mounted) {
      _menuTutorialScheduled = false;
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    TutorialCoachMark(
      targets: _buildMenuTargets(l10n),
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: l10n.tutorialSkip,
      paddingFocus: 12,
      onFinish: () => unawaited(TutorialService.markCompleted(TutorialFlow.menu)),
      onSkip: () {
        unawaited(TutorialService.markCompleted(TutorialFlow.menu));
        return true;
      },
    ).show(context: context);
  }

  bool _areMenuTargetsReady() {
    return _playButtonKey.currentContext != null &&
        _leaderboardButtonKey.currentContext != null &&
        _howToPlayButtonKey.currentContext != null &&
        _profileButtonKey.currentContext != null &&
        _volumeButtonKey.currentContext != null;
  }

  List<TargetFocus> _buildMenuTargets(AppLocalizations l10n) {
    return [
      TargetFocus(
        identify: 'play-button',
        keyTarget: _playButtonKey,
        contents: [
          TargetContent(
            child: TutorialCard(
              title: l10n.tutorialMenuPlayTitle,
              description: l10n.tutorialMenuPlayDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'leaderboard-button',
        keyTarget: _leaderboardButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialMenuLeaderboardTitle,
              description: l10n.tutorialMenuLeaderboardDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'how-to-play-button',
        keyTarget: _howToPlayButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialMenuHowToPlayTitle,
              description: l10n.tutorialMenuHowToPlayDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'profile-button',
        keyTarget: _profileButtonKey,
        contents: [
          TargetContent(
            child: TutorialCard(
              title: l10n.tutorialMenuProfileTitle,
              description: l10n.tutorialMenuProfileDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'volume-button',
        keyTarget: _volumeButtonKey,
        contents: [
          TargetContent(
            child: TutorialCard(
              title: l10n.tutorialMenuVolumeTitle,
              description: l10n.tutorialMenuVolumeDescription,
            ),
          ),
        ],
      ),
    ];
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
            RiveWidget(
              controller: controller,
              fit: Fit.cover,
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
                child: KeyedSubtree(
                  key: _playButtonKey,
                  child: InkWell(
                    onTap: () {
                      unawaited(AudioService.instance.playUiConfirmSound());
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        transitionAnimationController: AnimationController(vsync: this, duration: Duration(milliseconds: 500)),
                        isScrollControlled: true,
                        builder: (_) => PlayMenu(playerUid: _playerUid ?? ''),
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
              ),
              SizedBox(height: 150),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // if (user != null && !user.isAnonymous)
                    IconButton(
                      key: _leaderboardButtonKey,
                      onPressed: () {
                        unawaited(AudioService.instance.playUiConfirmSound());
                        unawaited(AudioService.instance.playNavigationSound());
                        final playerUid = user?.uid ?? _playerUid;
                        if (playerUid == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeaderboardScreen(playerUid: playerUid),
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
                      key: _howToPlayButtonKey,
                      onPressed: () {
                        unawaited(AudioService.instance.playUiConfirmSound());
                        unawaited(AudioService.instance.playNavigationSound());

                        // final participant = MatchParticipantResult(
                        //   userId: 'user1',
                        //   username: 'Player1',
                        //   color: 'blue',
                        //   score: 10,
                        //   expectedScore: 8,
                        //   previousRating: 1500,
                        //   newRating: 1515,
                        //   ratingDelta: 15,
                        //   gamesPlayed: 100,
                        //   wins: 60,
                        //   losses: 40,
                        //   kFactor: 32,
                        //   tier: 'Gold',
                        //   season: '2024',
                        //   goldBalance: 500,
                        //   goldReward: 10,
                        // );

                        // final result = MatchResult(
                        //   gameId: 'gameId',
                        //   winnerColor: 'blue',
                        //   participants: [
                        //     participant,
                        //     MatchParticipantResult(
                        //       userId: 'user2',
                        //       username: 'Player2',
                        //       color: 'red',
                        //       score: 5,
                        //       expectedScore: 7,
                        //       previousRating: 1500,
                        //       newRating: 1485,
                        //       ratingDelta: -15,
                        //       gamesPlayed: 100,
                        //       wins: 55,
                        //       losses: 45,
                        //       kFactor: 32,
                        //       tier: 'Gold',
                        //       season: '2024',
                        //     ),
                        //   ],
                        //   processedAt: DateTime.now(),
                        // );

                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => MatchResultScreen(
                        //       result: result,
                        //       participant: participant,
                        //       onExitToMenu: () {},
                        //     ),
                        //   ),
                        // );

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
                    return StreamBuilder<UserProfile?>(
                      stream: _firestoreService.watchUserProfile(user.uid),
                      builder: (context, profileSnapshot) {
                        final profile = profileSnapshot.data;
                        final username = profile?.username ?? user.displayName ?? user.email ?? 'player';
                        final photoUrl = profile?.photoUrl ?? user.photoURL;
                        final goldBalance = profile?.goldBalance ?? 0;
                        return KeyedSubtree(
                          key: _profileButtonKey,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _GoldBalanceBadge(
                                  amount: goldBalance,
                                  onTap: () => _openGoldStatement(user.uid),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    unawaited(AudioService.instance.playUiConfirmSound());
                                    showDialog(
                                      context: context,
                                      builder: (context) => ProfileModal(
                                        user: user,
                                        username: username,
                                        photoUrl: photoUrl,
                                      ),
                                    );
                                  },
                                  child: UsernameAvatar(
                                    username: username,
                                    tooltip: username,
                                    imageUrl: photoUrl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return KeyedSubtree(
                      key: _profileButtonKey,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextButton(
                          onPressed: () {
                            unawaited(AudioService.instance.playUiConfirmSound());
                            unawaited(AudioService.instance.playNavigationSound());
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
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  key: _volumeButtonKey,
                  icon: const Icon(Icons.volume_up, color: Colors.black),
                  onPressed: _openVolumeSettings,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldBalanceBadge extends StatelessWidget {
  const _GoldBalanceBadge({required this.amount, required this.onTap});

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Material(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/coins.png',
                width: 22,
              ),
              const SizedBox(width: 6),
              Text(
                '$amount',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
