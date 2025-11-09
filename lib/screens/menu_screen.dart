import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/ai_difficulty.dart';
import '../models/game_mode.dart';
import '../models/leaderboard_entry.dart';
import '../services/firestore_service.dart';
import '../services/ranking_service.dart';
import '../services/theme_manager.dart';
import '../widgets/styled_button.dart';
import './game_lobby_screen.dart';
import './how_to_play_screen.dart';
import './interstitial_ad_screen.dart';
import './login_screen.dart';
import './onitama_home.dart';
import './profile_modal.dart';
import 'history_game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final RankingService _rankingService = RankingService();
  final TextEditingController _gameIdController = TextEditingController();

  String? _playerUid;
  StreamSubscription? _gameSubscription;
  Timer? _gameCreationTimer;
  StreamSubscription<User?>? _authStateChangesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        // Rebuild the widget when auth state changes
      });
    });
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _gameCreationTimer?.cancel();
    _authStateChangesSubscription?.cancel();
    super.dispose();
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

  void _showDifficultyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectDifficulty),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: GameMode.pvai,
                        aiDifficulty: AIDifficulty.easy,
                        isHost: true,
                      ),
                    ),
                  ),
                );
              },
              text: l10n.easy,
            ),
            const SizedBox(height: 10),
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: GameMode.pvai,
                        aiDifficulty: AIDifficulty.medium,
                        isHost: true,
                      ),
                    ),
                  ),
                );
              },
              text: l10n.medium,
            ),
            const SizedBox(height: 10),
            StyledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterstitialAdScreen(
                      navigateTo: OnitamaHome(
                        gameMode: GameMode.pvai,
                        aiDifficulty: AIDifficulty.hard,
                        isHost: true,
                      ),
                    ),
                  ),
                );
              },
              text: l10n.hard,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createGame() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _playerUid;
    if (currentUid == null) return;
    final gameId = await _firestoreService.createGame(currentUid);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: currentUid),
      ),
    );
  }

  Future<void> _joinGame() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _playerUid;
    if (currentUid == null) return;
    final gameId = _gameIdController.text.trim();
    if (gameId.isNotEmpty) {
      if (!mounted) return;
      _firestoreService.joinGame(gameId, currentUid);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameLobbyScreen(gameId: gameId, playerUid: currentUid),
        ),
      );
    }
  }

  Future<void> _findOrCreateGame() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _playerUid;
    if (currentUid == null) return;
    _showWaitingDialog();

    final result = await _firestoreService.findOrCreateGame(currentUid);
    final gameId = result['gameId'];
    final isHost = result['isHost'];
    final inProgress = result['inProgress'] ?? false;

    if (inProgress) {
      if (!mounted) return;
      Navigator.pop(context); // Close waiting dialog
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnitamaHome(
            gameMode: GameMode.online,
            gameId: gameId,
            playerUid: currentUid,
            isHost: isHost,
          ),
        ),
      );
      return;
    }

    if (isHost) {
      _gameCreationTimer = Timer(const Duration(seconds: 20), () {
        _gameSubscription?.cancel();
        _firestoreService.convertToPvAI(gameId);
        if (!mounted) return;
        Navigator.pop(context); // Close waiting dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnitamaHome(
              gameMode: GameMode.online,
              gameId: gameId,
              playerUid: currentUid,
              isHost: true,
              hasDelay: true,
            ),
          ),
        );
      });

      _gameSubscription = _firestoreService.streamGame(gameId).listen((game) {
        if (game.players.length > 1) {
          _gameCreationTimer?.cancel();
          if (!mounted) return;
          Navigator.pop(context); // Close waiting dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OnitamaHome(
                gameMode: GameMode.online,
                gameId: gameId,
                playerUid: currentUid,
                isHost: true,
              ),
            ),
          );
          _gameSubscription?.cancel();
        }
      });
    } else {
      if (!mounted) return;
      Navigator.pop(context); // Close waiting dialog
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnitamaHome(
            gameMode: GameMode.online,
            gameId: gameId,
            playerUid: currentUid,
            isHost: false,
          ),
        ),
      );
    }
  }

  void _showWaitingDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.matchmaking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(l10n.waitingForAnOpponent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = ThemeManager.cachedImage('default-background');
    return Container(
      decoration: background != null
          ? BoxDecoration(
              image: DecorationImage(
                image: background,
                fit: BoxFit.cover,
              ),
            )
          : null,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(48),
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 250,
                        ),
                      ),
                      Text(
                        l10n.gameOfTheMasters,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 30),
                      StyledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InterstitialAdScreen(
                                navigateTo: OnitamaHome(
                                  gameMode: GameMode.pvp,
                                  isHost: true,
                                ),
                              ),
                            ),
                          );
                        },
                        text: l10n.localMultiplayer,
                        icon: Icons.people,
                      ),
                      const SizedBox(height: 20),
                      StyledButton(
                        onPressed: () => _showDifficultyDialog(context),
                        text: l10n.playerVsAi,
                        icon: Icons.computer,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: StyledButton(
                              onPressed: _findOrCreateGame,
                              text: l10n.onlineMultiplayer,
                              icon: Icons.public,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => HistoryGameScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ExpansionTile(
                        title: Text(l10n.privateGame),
                        children: [
                          const SizedBox(height: 10),
                          StyledButton(
                            onPressed: _createGame,
                            text: l10n.createOnlineGame,
                            icon: Icons.add,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _gameIdController,
                            decoration: InputDecoration(
                              labelText: l10n.gameId,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          StyledButton(
                            onPressed: _joinGame,
                            text: l10n.joinOnlineGame,
                            icon: Icons.login,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HowToPlayScreen(),
                            ),
                          );
                        },
                        label: Text(l10n.howToPlay),
                        icon: const Icon(Icons.rule),
                      ),
                      _buildLeaderboardSection(),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasData && snapshot.data != null && !snapshot.data!.isAnonymous) {
                      final user = snapshot.data!;
                      final initial = user.displayName?.isNotEmpty ?? false
                          ? user.displayName![0].toUpperCase()
                          : (user.email?.isNotEmpty ?? false ? user.email![0].toUpperCase() : '?');
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => ProfileModal(user: user),
                            );
                          },
                          child: CircleAvatar(
                            child: Text(initial),
                          ),
                        ),
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
                          child: const Text('Sign In'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    if (_playerUid == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.leaderboardTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreamBuilder<LeaderboardEntry?>(
              stream: _rankingService.watchPlayerEntry(_playerUid!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final entry = snapshot.data;
                if (entry == null) {
                  return Text(
                    l10n.leaderboardInvite,
                  );
                }
                final winRate = (entry.winRate * 100).toStringAsFixed(1);
                final tierLabel = _localizedTier(entry.tier, l10n);
                return Text(
                  l10n.leaderboardPlayerSummary(entry.rating, tierLabel, winRate),
                );
              },
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<LeaderboardEntry>>(
              stream: _rankingService.watchTopEntries(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data;
                if (entries == null || entries.isEmpty) {
                  return Text(l10n.leaderboardEmpty);
                }

                return Column(
                  children: entries
                      .map(
                        (entry) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text('${entry.rank ?? '-'}'),
                          ),
                          title: Text(entry.username),
                          subtitle: Text(l10n.leaderboardPlayerSubtitle(entry.rating, _localizedTier(entry.tier, l10n))),
                          trailing: Text(
                            l10n.leaderboardWinRateShort((entry.winRate * 100).toStringAsFixed(0)),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _localizedTier(String? tier, AppLocalizations l10n) {
    switch (tier?.toLowerCase()) {
      case 'bronze':
        return l10n.leaderboardTierBronze;
      case 'silver':
        return l10n.leaderboardTierSilver;
      case 'gold':
        return l10n.leaderboardTierGold;
      case 'platine':
      case 'platinum':
        return l10n.leaderboardTierPlatine;
      case 'diamond':
        return l10n.leaderboardTierDiamond;
      default:
        return tier ?? '-';
    }
  }
}
