import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../l10n/app_localizations.dart';
import '../logic/game_state.dart';
import '../models/ai_difficulty.dart';
import '../models/card_model.dart';
import '../models/firestore_game.dart';
import '../models/game_mode.dart';
import '../models/match_result.dart';
import '../models/piece_type.dart';
import '../models/player.dart';
import '../models/user_profile.dart';
import '../models/win_condition.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';
import '../services/ranking_service.dart';
import '../services/route_observer.dart';
import '../services/theme_manager.dart';
import '../services/tutorial_service.dart';
import '../utils/extensions.dart';
import '../widgets/board_widget.dart';
import '../widgets/card_widget.dart';
import '../widgets/tutorial_card.dart';
import '../widgets/username_avatar.dart';
import 'historic_game_detail_screen.dart';
import 'interstitial_ad_screen.dart';
import 'match_result_screen.dart';
import 'rewarded_ad_screen.dart';

class OnitamaHome extends StatefulWidget {
  final GameMode gameMode;
  final AIDifficulty? aiDifficulty;
  final String? gameId;
  final String? playerUid;
  final bool? isHost;
  final bool hasDelay;

  const OnitamaHome({
    required this.gameMode,
    super.key,
    this.aiDifficulty,
    this.gameId,
    this.playerUid,
    this.isHost,
    this.hasDelay = false,
  });

  @override
  OnitamaHomeState createState() => OnitamaHomeState();
}

class OnitamaHomeState extends State<OnitamaHome> with RouteAware {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  GameState? _gameState;
  final FirestoreService _firestoreService = FirestoreService();
  final RankingService _rankingService = RankingService();
  Stream<FirestoreGame>? _gameStream;
  StreamSubscription? _gameSubscription;
  FirestoreGame? _firestoreGame;
  bool _rankingSubmitted = false;
  bool _isEndDialogVisible = false;
  final Map<String, UserProfile> _profileCache = <String, UserProfile>{};
  final Set<String> _loadingProfileUids = <String>{};
  final Map<String, int?> _ratingCache = <String, int?>{};
  final Set<String> _loadingRatingUids = <String>{};
  final Map<PlayerColor, String> _fallbackUsernames = <PlayerColor, String>{};
  final Random _random = Random();
  PageRoute<dynamic>? _route;
  final GlobalKey _opponentCardsKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _playerCardsKey = GlobalKey();
  final GlobalKey _reserveCardKey = GlobalKey();
  bool? _shouldShowGameplayTutorial;
  bool _gameplayTutorialShowing = false;
  Timer? _clockTimer;
  DateTime? _lastClockTick;
  PlayerColor? _lastTickPlayer;
  GameMode get _effectiveGameMode => _gameState?.gameMode ?? widget.gameMode;
  bool get _isLocalAiMatch => widget.gameMode == GameMode.pvai && widget.gameId == null;
  bool get _isOnlineAiMatch {
    if (widget.gameMode != GameMode.online) return false;
    final players = _firestoreGame?.players;
    if (players == null) return false;
    return players.containsValue('ai');
  }

  bool get _timersEnabled {
    if (_isLocalAiMatch) {
      return false;
    }
    if (widget.gameMode != GameMode.online) {
      return true;
    }
    final game = _firestoreGame;
    if (game == null) {
      return false;
    }
    if (game.status != 'inprogress') {
      return false;
    }
    return _bothPlayersReady(game);
  }

  bool _bothPlayersReady(FirestoreGame game) {
    final blue = game.players['blue'] ?? '';
    final red = game.players['red'] ?? '';
    return blue.isNotEmpty && red.isNotEmpty;
  }

  bool _shouldSyncClockWithServer(FirestoreGame game) {
    if (widget.gameMode != GameMode.online) {
      return true;
    }
    if (game.status != 'inprogress') {
      return false;
    }
    return _bothPlayersReady(game);
  }

  static const List<String> _fakeFirstNames = <String>[
    'Aiko',
    'Hiro',
    'Kenji',
    'Mika',
    'Ren',
    'Sora',
    'Taro',
    'Yumi',
    'Daichi',
    'Kumi',
  ];

  static const List<String> _fakeLastNames = <String>[
    'Tanaka',
    'Sato',
    'Nakamura',
    'Yamamoto',
    'Suzuki',
    'Fujimoto',
    'Kobayashi',
    'Hayashi',
    'Okada',
    'Shimizu',
  ];

  @override
  void initState() {
    super.initState();
    ThemeManager.clearPlayerThemes();
    _startHomeMusic();
    if (widget.gameId != null) {
      _gameStream = _firestoreService.streamGame(widget.gameId!);
      _loadGameState();
    }

    if (widget.gameMode == GameMode.online) {
      _gameSubscription = _gameStream?.listen((firestoreGame) {
        _firestoreGame = firestoreGame;
        _maybeLoadPlayerProfiles(firestoreGame.players);
        _applyPlayerThemesFromProfiles();
        final oldSelectedCell = _gameState?.selectedCell;
        final oldSelectedCard = _gameState?.selectedCardForMove;
        final previousHistoryLength = _gameState?.gameHistory.length ?? 0;

        final needsFreshState = _gameState == null || _gameState!.gameMode != firestoreGame.gameMode;
        GameState syncedState;
        if (needsFreshState) {
          syncedState = GameState.fromFirestore(
            firestoreGame,
            widget.gameMode,
            widget.aiDifficulty,
          );
        } else {
          syncedState = _gameState!;
          syncedState.updateFromFirestore(
            firestoreGame,
            fallbackAi: widget.aiDifficulty,
          );
        }
        syncedState.selectedCell = oldSelectedCell;
        syncedState.selectedCardForMove = oldSelectedCard;
        if (_shouldSyncClockWithServer(firestoreGame)) {
          syncedState.syncClockWithAnchor(DateTime.now().millisecondsSinceEpoch);
        } else {
          syncedState.lastClockUpdateMillis = DateTime.now().millisecondsSinceEpoch;
        }

        setState(() {
          _gameState = syncedState;
          if (_gameState?.lastMove == null && (ModalRoute.of(context)?.isCurrent != true)) {
            Navigator.of(context).pop();
          }

          _gameState?.verifyWin(_showEndDialog);
        });
        _ensureClockStarted();
        _refreshClockAnchor();

        final newHistoryLength = _gameState?.gameHistory.length ?? 0;
        if (newHistoryLength > previousHistoryLength) {
          _triggerMoveSound();
        }

        _submitRankingIfNeeded(firestoreGame);
        _maybeShowGameplayTutorial();
      });
    } else {
      _gameState = GameState(
        gameMode: widget.gameMode,
        aiDifficulty: widget.aiDifficulty,
      );
    }
    _ensureClockStarted();
    _refreshClockAnchor();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGameplayTutorial());
  }

  Future<void> _loadGameState() async {
    if (widget.gameId != null) {
      final firestoreGame = await _firestoreService.getGame(widget.gameId!);
      if (firestoreGame != null) {
        final needsFreshState = _gameState == null || _gameState!.gameMode != firestoreGame.gameMode;
        GameState syncedState;
        if (needsFreshState) {
          syncedState = GameState.fromFirestore(
            firestoreGame,
            widget.gameMode,
            widget.aiDifficulty,
          );
        } else {
          syncedState = _gameState!;
          syncedState.updateFromFirestore(
            firestoreGame,
            fallbackAi: widget.aiDifficulty,
          );
        }
        if (_shouldSyncClockWithServer(firestoreGame)) {
          syncedState.syncClockWithAnchor(DateTime.now().millisecondsSinceEpoch);
        } else {
          syncedState.lastClockUpdateMillis = DateTime.now().millisecondsSinceEpoch;
        }
        setState(() {
          _firestoreGame = firestoreGame;
          _gameState = syncedState;
        });
        _maybeLoadPlayerProfiles(firestoreGame.players);
        _applyPlayerThemesFromProfiles();
        _ensureClockStarted();
        _refreshClockAnchor();
        _maybeShowGameplayTutorial();
      }
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    appRouteObserver.unsubscribe(this);
    unawaited(AudioService.instance.stopBackground());
    _clockTimer?.cancel();
    ThemeManager.clearPlayerThemes();
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
  void didPush() {
    _startHomeMusic();
  }

  @override
  void didPopNext() {
    _startHomeMusic();
  }

  void _startHomeMusic() {
    unawaited(AudioService.instance.playHomeMusic());
  }

  Future<void> _returnToMenuWithAd() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => InterstitialAdScreen(
          onFinished: () {
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
      ),
    );
  }

  void _onCellTap(int r, int c) {
    if (widget.gameMode == GameMode.online) {
      if ((_gameState!.currentPlayer == PlayerColor.red && widget.isHost!) || (_gameState!.currentPlayer == PlayerColor.blue && !widget.isHost!)) {
        return;
      }
    }

    final previousHistoryLength = _gameState!.gameHistory.length;
    _gameState!.onCellTap(r, c, _showEndDialog);
    final moveExecuted = _gameState!.gameHistory.length > previousHistoryLength;
    setState(() {});
    _refreshClockAnchor();

    if (moveExecuted) {
      _triggerMoveSound();
      if (widget.gameMode == GameMode.online) {
        unawaited(_persistOnlineGame(includeBoard: true));
      }
    }

    if (_shouldTriggerAiMove()) {
      _handleAIMove();
    }
  }

  Future<void> _handleAIMove() async {
    final gameState = _gameState;
    if (gameState == null || !_isAiControlled(gameState.currentPlayer)) {
      return;
    }
    final isWinByCapture = gameState.isWinByCapture();
    final lastMove = gameState.lastMove;
    final isWinByTemple = lastMove != null &&
        gameState.isWinByTemple(
          lastMove.to.r,
          lastMove.to.c,
          PlayerColor.blue,
        );
    final previousHistoryLength = gameState.gameHistory.length;
    if (gameState.gameMode == GameMode.pvai && !isWinByCapture && !isWinByTemple) {
      await gameState.makeAIMove(_showEndDialog, widget.hasDelay && _isOnlineAiMatch);
      if (!mounted) {
        return;
      }
      setState(() {
        _gameState = gameState;
      });
      _refreshClockAnchor();
    }
    final aiMoved = gameState.gameHistory.length > previousHistoryLength;
    if (aiMoved) {
      _triggerMoveSound();
    }
    if (_firestoreGame != null && widget.gameMode == GameMode.online) {
      await _persistOnlineGame(includeBoard: true);
    }
  }

  void _ensureClockStarted() {
    if (_gameState == null || !_timersEnabled) {
      _clockTimer?.cancel();
      _clockTimer = null;
      return;
    }
    _lastTickPlayer ??= _gameState!.currentPlayer;
    _lastClockTick ??= DateTime.now();
    _gameState!.lastClockUpdateMillis ??= _lastClockTick!.millisecondsSinceEpoch;
    _clockTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _handleClockTick());
  }

  void _refreshClockAnchor() {
    if (_gameState == null || !_timersEnabled) {
      return;
    }
    _lastTickPlayer = _gameState!.currentPlayer;
    _lastClockTick = DateTime.now();
    _gameState!.lastClockUpdateMillis = _lastClockTick!.millisecondsSinceEpoch;
  }

  void _handleClockTick() {
    if (!mounted || _gameState == null || _gameState!.winner != null || !_timersEnabled) {
      return;
    }
    final now = DateTime.now();
    _lastClockTick ??= now;
    final currentPlayer = _gameState!.currentPlayer;

    if (_lastTickPlayer != currentPlayer) {
      _lastTickPlayer = currentPlayer;
      _lastClockTick = now;
      return;
    }

    final delta = now.difference(_lastClockTick!).inMilliseconds;
    if (delta <= 0) {
      return;
    }
    _lastClockTick = now;
    _gameState!.lastClockUpdateMillis = now.millisecondsSinceEpoch;

    if (!_shouldTickForCurrentPlayer(currentPlayer)) {
      return;
    }

    _gameState!.decreaseTime(currentPlayer, delta);
    final remaining = _gameState!.timeRemaining(currentPlayer);
    if (remaining.inMilliseconds <= 0) {
      _handleTimeout(currentPlayer);
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool _shouldTickForCurrentPlayer(PlayerColor currentPlayer) {
    return _timersEnabled;
  }

  Future<void> _persistOnlineGame({required bool includeBoard}) async {
    if (!mounted || widget.gameMode != GameMode.online || widget.gameId == null || _firestoreGame == null || _gameState == null) {
      return;
    }
    final updatedGame = _firestoreGame!.copyWith(
      board: includeBoard ? _gameState!.board : null,
      redHand: includeBoard ? _gameState!.redHand : null,
      blueHand: includeBoard ? _gameState!.blueHand : null,
      reserveCard: includeBoard ? _gameState!.reserveCard : null,
      currentPlayer: includeBoard ? _gameState!.currentPlayer : null,
      lastMove: includeBoard ? _gameState!.lastMoveAsMap : null,
      status: _gameState!.winner != null ? 'finished' : null,
      winner: _gameState!.winner,
      gameHistory: includeBoard ? _gameState!.gameHistory : null,
      blueTimeMillis: _gameState!.blueTimeMillis,
      redTimeMillis: _gameState!.redTimeMillis,
      lastClockUpdateMillis: _gameState!.lastClockUpdateMillis ?? DateTime.now().millisecondsSinceEpoch,
    );
    _firestoreGame = updatedGame;
    await _firestoreService.updateGame(widget.gameId!, updatedGame);
  }

  bool _shouldTriggerAiMove() {
    if (_gameState == null) {
      return false;
    }
    return _isAiControlled(_gameState!.currentPlayer);
  }

  bool _isAiControlled(PlayerColor color) {
    if (_effectiveGameMode == GameMode.pvai) {
      return color == PlayerColor.red;
    }
    if (_isOnlineAiMatch) {
      final players = _firestoreGame?.players;
      if (players == null) {
        return false;
      }
      final key = color == PlayerColor.blue ? 'blue' : 'red';
      return players[key] == 'ai';
    }
    return false;
  }

  void _handleTimeout(PlayerColor loser) {
    if (!mounted || _gameState == null || _gameState!.winner != null) {
      return;
    }
    final winner = _gameState!.opponent(loser);
    _gameState!.winner = winner;
    _gameState!.lastClockUpdateMillis = DateTime.now().millisecondsSinceEpoch;
    setState(() {});
    if (widget.gameMode == GameMode.online) {
      unawaited(_persistOnlineGame(includeBoard: true));
    }
    _showEndDialog(winner, WinCondition.timeout);
  }

  void _triggerMoveSound() {
    final move = _gameState?.lastMove;
    if (move == null) return;
    final piece = _gameState?.board[move.to.r][move.to.c];
    if (piece == null) {
      unawaited(AudioService.instance.playRandomMoveSound());
      return;
    }
    if (piece.type == PieceType.master) {
      unawaited(AudioService.instance.playSpecialMasterMoveSound());
    } else {
      unawaited(AudioService.instance.playRandomMoveSound());
    }
  }

  void _onCardTap(CardModel card) {
    if (widget.gameMode == GameMode.online) {
      if ((_gameState!.currentPlayer == PlayerColor.red && widget.isHost!) || (_gameState!.currentPlayer == PlayerColor.blue && !widget.isHost!)) {
        return;
      }
    }

    final wasSelected = _gameState!.selectedCardForMove == card;
    setState(() {
      _gameState!.onCardTap(card);
    });
    final isSelectedNow = _gameState!.selectedCardForMove == card;
    if (!wasSelected && isSelectedNow) {
      unawaited(AudioService.instance.playUiSelectSound());
    }
  }

  void _showEndDialog(PlayerColor winner, WinCondition condition) {
    final l10n = AppLocalizations.of(context)!;
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final winnerName = _getWinnerName(winner);
    final conditionText = condition == WinCondition.capture
        ? l10n.wonByCapture
        : condition == WinCondition.temple
            ? l10n.wonByTemple
            : l10n.wonByTimeout;
    final text = '$winnerName $conditionText';

    if (widget.gameMode != GameMode.online) unawaited(AudioService.instance.playSpecialWinSound());
    _isEndDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          l10n.gameOver,
          style: TextStyle(
            fontFamily: 'SpellOfAsia',
          ),
        ),
        content: widget.gameMode == GameMode.online
            ? Container(
                height: 40,
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Text(text),
        actions: [
          if (widget.gameMode != GameMode.online)
            TextButton(
              child: Text(l10n.exit),
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(_returnToMenuWithAd());
              },
            ),
          if (widget.gameMode == GameMode.pvai && winner == PlayerColor.red)
            TextButton(
              child: Text(l10n.undoWithAd),
              onPressed: () {
                Navigator.of(context).pop(); // fecha o diálogo
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RewardedAdScreen(
                      onReward: () async {
                        await _undoLastTwoAndPersist();
                      },
                    ),
                  ),
                );
              },
            ),
          if (_gameState!.gameMode == GameMode.pvp)
            TextButton(
              child: Text(l10n.restart),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => OnitamaHome(
                      gameMode: widget.gameMode,
                      aiDifficulty: widget.aiDifficulty,
                      gameId: widget.gameId,
                      playerUid: widget.playerUid,
                      isHost: widget.isHost,
                      hasDelay: widget.hasDelay,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ).then((_) {
      _isEndDialogVisible = false;
    });
  }

  Future<void> _submitRankingIfNeeded(FirestoreGame game) async {
    if (_rankingSubmitted || widget.gameMode != GameMode.online || widget.gameId == null) {
      return;
    }
    if (game.status != 'finished') {
      return;
    }

    _rankingSubmitted = true;
    try {
      final result = await _rankingService.submitMatchResult(widget.gameId!);
      final participant = _participantForCurrentUser(result);
      if (participant == null || !mounted) {
        return;
      }
      await _dismissEndDialogIfNeeded();
      if (!mounted) return;
      await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: MatchResultScreen(
              result: result,
              participant: participant,
              onExitToMenu: _exitToMenuAfterResult,
            ),
          ),
        ),
      );
    } catch (error) {
      debugPrint('Failed to submit ranking for game ${widget.gameId}: $error');
      _rankingSubmitted = false;
    }
  }

  MatchParticipantResult? _participantForCurrentUser(MatchResult result) {
    final uid = widget.playerUid;
    if (uid == null) {
      return null;
    }
    for (final participant in result.participants) {
      if (participant.userId == uid) {
        return participant;
      }
    }
    return null;
  }

  Future<void> _dismissEndDialogIfNeeded() async {
    if (!_isEndDialogVisible || !mounted) {
      return;
    }
    _isEndDialogVisible = false;
    await Navigator.of(context, rootNavigator: true).maybePop();
  }

  void _exitToMenuAfterResult() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    unawaited(_returnToMenuWithAd());
  }

  Future<void> _undoLastTwoAndPersist() async {
    if (_gameState == null) return;
    final ok = _gameState!.undoLastTwoMoves();
    if (!ok) return;
    setState(() {});
  }

  void _maybeLoadPlayerProfiles(Map<String, String> players) {
    if (widget.gameMode != GameMode.online) return;
    players.forEach((_, uid) {
      if (uid.isEmpty || uid == 'ai') return;
      _loadProfileIfNeeded(uid);
      _loadRatingIfNeeded(uid);
    });
  }

  void _loadProfileIfNeeded(String uid) {
    if (_profileCache.containsKey(uid) || _loadingProfileUids.contains(uid)) return;
    _loadingProfileUids.add(uid);
    _firestoreService.fetchUserProfile(uid).then((profile) {
      if (!mounted) return;
      setState(() {
        _profileCache[uid] = profile ?? UserProfile(id: uid, username: '');
        _loadingProfileUids.remove(uid);
        _applyPlayerThemesFromProfiles();
      });
    }).catchError((error) {
      debugPrint('Failed to load profile for $uid: $error');
      if (!mounted) return;
      setState(() {
        _profileCache[uid] = UserProfile(id: uid, username: '');
        _loadingProfileUids.remove(uid);
        _applyPlayerThemesFromProfiles();
      });
    });
  }

  void _applyPlayerThemesFromProfiles() {
    final players = _firestoreGame?.players;
    if (players == null) return;
    final blueUid = players['blue'];
    final redUid = players['red'];
    ThemeManager.setPlayerTheme(PlayerColor.blue, blueUid != null ? _profileCache[blueUid]?.theme : null);
    ThemeManager.setPlayerTheme(PlayerColor.red, redUid != null ? _profileCache[redUid]?.theme : null);
  }

  void _loadRatingIfNeeded(String uid) {
    if (_ratingCache.containsKey(uid) || _loadingRatingUids.contains(uid)) return;
    _loadingRatingUids.add(uid);
    _rankingService.fetchPlayerEntry(uid).then((entry) {
      if (!mounted) return;
      setState(() {
        _ratingCache[uid] = entry?.rating;
        _loadingRatingUids.remove(uid);
      });
    }).catchError((error) {
      debugPrint('Failed to load rating for $uid: $error');
      if (!mounted) return;
      setState(() {
        _ratingCache[uid] = null;
        _loadingRatingUids.remove(uid);
      });
    });
  }

  String? _usernameForColor(PlayerColor color) {
    if (widget.gameMode != GameMode.online) {
      return null;
    }
    final players = _firestoreGame?.players;
    if (players == null) return null;
    final key = color == PlayerColor.blue ? 'blue' : 'red';
    final uid = players[key];
    if (uid == null || uid.isEmpty || uid == 'ai') {
      return null;
    }
    final profile = _profileCache[uid];
    final username = profile?.username;
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return null;
  }

  String? _photoUrlForColor(PlayerColor color) {
    if (widget.gameMode != GameMode.online) {
      return null;
    }
    final players = _firestoreGame?.players;
    if (players == null) return null;
    final key = color == PlayerColor.blue ? 'blue' : 'red';
    final uid = players[key];
    if (uid == null || uid.isEmpty || uid == 'ai') {
      return null;
    }
    return _profileCache[uid]?.photoUrl;
  }

  int? _ratingForColor(PlayerColor color) {
    if (widget.gameMode != GameMode.online) {
      return null;
    }
    final players = _firestoreGame?.players;
    if (players == null) return null;
    final key = color == PlayerColor.blue ? 'blue' : 'red';
    final uid = players[key];
    if (uid == null || uid.isEmpty || uid == 'ai') {
      return null;
    }
    if (_ratingCache.containsKey(uid)) {
      return _ratingCache[uid];
    }
    return null;
  }

  String _fakeUsernameForColor(PlayerColor color) {
    return _fallbackUsernames.putIfAbsent(color, () {
      final first = _fakeFirstNames[_random.nextInt(_fakeFirstNames.length)];
      final last = _fakeLastNames[_random.nextInt(_fakeLastNames.length)];
      final suffix = (_random.nextInt(900) + 100).toString();
      return '$first$last$suffix';
    });
  }

  String _getWinnerName(PlayerColor winner) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.gameMode == GameMode.online) {
      final username = _usernameForColor(winner);
      if (username != null) {
        return username;
      }
      return _fakeUsernameForColor(winner);
    } else {
      return winner == PlayerColor.blue ? l10n.blue : l10n.red;
    }
  }

  String _getPlayerLabel(PlayerColor player) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.gameMode == GameMode.online) {
      final username = _usernameForColor(player);
      if (username != null) {
        return username;
      }
      return _fakeUsernameForColor(player);
    }
    if (widget.gameMode == GameMode.pvp) {
      return player == PlayerColor.red ? l10n.red : l10n.blue;
    }
    if (widget.isHost!) {
      // Host is always blue
      return player == PlayerColor.blue ? l10n.you : l10n.opponent;
    } else {
      // Guest is always red
      return player == PlayerColor.red ? l10n.you : l10n.opponent;
    }
  }

  String _getLocalizedCardName(BuildContext context, String cardName) {
    final l10n = AppLocalizations.of(context)!;
    switch (cardName) {
      case 'Tiger':
        return l10n.cardTiger;
      case 'Dragon':
        return l10n.cardDragon;
      case 'Frog':
        return l10n.cardFrog;
      case 'Rabbit':
        return l10n.cardRabbit;
      case 'Crab':
        return l10n.cardCrab;
      case 'Elephant':
        return l10n.cardElephant;
      case 'Goose':
        return l10n.cardGoose;
      case 'Rooster':
        return l10n.cardRooster;
      case 'Monkey':
        return l10n.cardMonkey;
      case 'Mantis':
        return l10n.cardMantis;
      case 'Horse':
        return l10n.cardHorse;
      case 'Ox':
        return l10n.cardOx;
      case 'Crane':
        return l10n.cardCrane;
      case 'Boar':
        return l10n.cardBoar;
      case 'Eel':
        return l10n.cardEel;
      case 'Cobra':
        return l10n.cardCobra;
      default:
        return cardName; // Fallback to original name if not found
    }
  }

  Future<void> _maybeShowGameplayTutorial() async {
    if (!mounted || _gameplayTutorialShowing) {
      return;
    }
    _shouldShowGameplayTutorial ??= await TutorialService.shouldShow(TutorialFlow.gameplay);
    if (_shouldShowGameplayTutorial != true) {
      return;
    }
    if (_gameState == null) {
      Future.delayed(const Duration(milliseconds: 200), _maybeShowGameplayTutorial);
      return;
    }
    const attempts = 8;
    var ready = _areGameplayTargetsReady();
    var tries = 0;
    while (!ready && tries < attempts && mounted) {
      await Future.delayed(const Duration(milliseconds: 150));
      ready = _areGameplayTargetsReady();
      tries++;
    }
    if (!ready || !mounted) {
      return;
    }
    _gameplayTutorialShowing = true;
    final l10n = AppLocalizations.of(context)!;
    TutorialCoachMark(
      targets: _buildGameplayTargets(l10n),
      colorShadow: Colors.black.withOpacity(0.75),
      textSkip: l10n.tutorialSkip,
      paddingFocus: 12,
      onFinish: () => unawaited(TutorialService.markCompleted(TutorialFlow.gameplay)),
      onSkip: () {
        unawaited(TutorialService.markCompleted(TutorialFlow.gameplay));
        return true;
      },
    ).show(context: context);
  }

  bool _areGameplayTargetsReady() {
    return _playerCardsKey.currentContext != null &&
        _opponentCardsKey.currentContext != null &&
        _reserveCardKey.currentContext != null &&
        _boardKey.currentContext != null;
  }

  List<TargetFocus> _buildGameplayTargets(AppLocalizations l10n) {
    return [
      TargetFocus(
        identify: 'player-cards',
        keyTarget: _playerCardsKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialGameplayPlayerCardsTitle,
              description: l10n.tutorialGameplayPlayerCardsDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'reserve-card',
        keyTarget: _reserveCardKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: TutorialCard(
              title: l10n.tutorialGameplayReserveTitle,
              description: l10n.tutorialGameplayReserveDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'board',
        keyTarget: _boardKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            child: TutorialCard(
              title: l10n.tutorialGameplayBoardTitle,
              description: l10n.tutorialGameplayBoardDescription,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'opponent-cards',
        keyTarget: _opponentCardsKey,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            child: TutorialCard(
              title: l10n.tutorialGameplayOpponentCardsTitle,
              description: l10n.tutorialGameplayOpponentCardsDescription,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildHands(PlayerColor player, Duration timeRemaining) {
    final hand = player == PlayerColor.red ? _gameState!.redHand : _gameState!.blueHand;
    final isPlayerTurn = _gameState!.currentPlayer == player;
    final isOnline = widget.gameMode == GameMode.online;
    final cards = hand
        .map(
          (c) => CardWidget(
            card: c,
            localizedName: _getLocalizedCardName(context, c.name),
            color: player == PlayerColor.red ? Colors.red : Colors.blue,
            isSelected: _gameState!.selectedCardForMove?.name == c.name,
            onTap: _onCardTap,
            invert: player == (widget.isHost! ? PlayerColor.blue : PlayerColor.red),
            canTap: isPlayerTurn,
            owner: player,
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: isOnline ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!isOnline)
            Text(
              _getPlayerLabel(player),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: player == PlayerColor.red ? Colors.red : Colors.blue,
                decoration: isPlayerTurn ? TextDecoration.underline : TextDecoration.none,
                decorationColor: player == PlayerColor.red ? Colors.red : Colors.blue,
              ),
            ),
          if (_timersEnabled) ...[
            _buildHandTimer(
              timeRemaining: timeRemaining,
              color: player,
              isActive: isPlayerTurn,
            ),
            12.0.spaceX,
          ],
          Spacer(),
          ...cards,
        ],
      ),
    );
  }

  Widget _buildHandTimer({
    required Duration timeRemaining,
    required PlayerColor color,
    required bool isActive,
  }) {
    final highlight = color == PlayerColor.red ? Colors.red : Colors.blue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isActive ? 0.95 : 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? highlight : highlight.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: highlight,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTime(timeRemaining),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return '0:00';
    }
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = ThemeManager.themedImage('background', owner: PlayerColor.blue);
    final background = bgImage != null
        ? Image(
            image: bgImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : null;

    final l10n = AppLocalizations.of(context)!;
    if (_gameState == null) {
      return Scaffold(
        backgroundColor: background != null ? Colors.transparent : null,
        body: Center(
          child: Text(l10n.loading),
        ),
      );
    }
    final player = widget.isHost! ? PlayerColor.blue : PlayerColor.red;
    final opponentPlayer = player == PlayerColor.red ? PlayerColor.blue : PlayerColor.red;
    final isPlayerTurn = _gameState!.currentPlayer == player;
    final username = _getPlayerLabel(player);
    final opponentUsername = _getPlayerLabel(opponentPlayer);
    final playerRating = _ratingForColor(player);
    final opponentRating = _ratingForColor(opponentPlayer);
    final playerPhotoUrl = _photoUrlForColor(player);
    final opponentPhotoUrl = _photoUrlForColor(opponentPlayer);
    final playerTimeRemaining = _gameState!.timeRemaining(player);
    final opponentTimeRemaining = _gameState!.timeRemaining(opponentPlayer);

    return StreamBuilder(
      stream: widget.gameMode == GameMode.online ? _gameStream : null,
      builder: (context, asyncSnapshot) {
        if (widget.gameMode == GameMode.online && asyncSnapshot.connectionState == ConnectionState.waiting && _gameState == null) {
          return Scaffold(body: Center(child: Text(l10n.loading)));
        }
        return Stack(
          children: [
            if (background != null) background,
            Scaffold(
              key: scaffoldKey,
              backgroundColor: background != null ? Colors.transparent : null,
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.settings),
                onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
              ),
              endDrawer: Drawer(
                child: SafeArea(
                  child: Column(
                    children: [
                      widget.gameMode != GameMode.online
                          ? ListTile(
                              leading: const Icon(Icons.refresh),
                              title: Text(l10n.restartGame),
                              onTap: () async {
                                final shouldRestart = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.restartGame),
                                    content: Text(l10n.areYouSureRestart),
                                    actions: [
                                      TextButton(
                                        child: Text(l10n.cancel),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(l10n.restart),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldRestart == true) {
                                  Navigator.of(context).pop(); // Close the drawer
                                  await Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => OnitamaHome(
                                        gameMode: widget.gameMode,
                                        aiDifficulty: widget.aiDifficulty,
                                        gameId: widget.gameId,
                                        playerUid: widget.playerUid,
                                        isHost: widget.isHost,
                                        hasDelay: widget.hasDelay,
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : ListTile(
                              leading: const Icon(Icons.flag_outlined),
                              title: Text(l10n.surrender),
                              onTap: () async {
                                final shouldSurrender = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.surrenderGame),
                                    content: Text(l10n.areYouSureSurrender),
                                    actions: [
                                      TextButton(
                                        child: Text(l10n.cancel),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(l10n.surrender),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldSurrender == true) {
                                  // Finaliza a partida, define o adversário como winner e status como finished
                                  if (_firestoreGame != null && widget.gameMode == GameMode.online) {
                                    final opponentColor = widget.isHost! ? PlayerColor.red : PlayerColor.blue;
                                    final updatedGame = _firestoreGame!.copyWith(
                                      status: 'finished',
                                      winner: opponentColor,
                                    );
                                    await _firestoreService.updateGame(
                                      widget.gameId!,
                                      updatedGame,
                                    );
                                  }
                                  Navigator.of(context).pop();
                                  unawaited(_returnToMenuWithAd());
                                }
                              },
                            ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(l10n.currentGameHistory),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => HistoricGameDetailScreen(
                                moves: _gameState!.gameHistory,
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      if (widget.gameMode != GameMode.online)
                        ListTile(
                          leading: const Icon(Icons.exit_to_app),
                          title: Text(l10n.exitGame),
                          onTap: () async {
                            final shouldExit = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(l10n.exitGame),
                                content: Text(l10n.areYouSureExit),
                                actions: [
                                  TextButton(
                                    child: Text(l10n.cancel),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child: Text(l10n.exit),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            );
                            if (shouldExit == true) {
                              Navigator.of(context).pop(); // Close the drawer
                              unawaited(_returnToMenuWithAd());
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (widget.gameMode == GameMode.online) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isPlayerTurn
                                          ? player == PlayerColor.red
                                              ? Colors.red
                                              : Colors.blue
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: UsernameAvatar(
                                    username: username,
                                    imageUrl: playerPhotoUrl,
                                    size: 30,
                                  ),
                                ),
                                8.0.spaceX,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: player == PlayerColor.red ? Colors.red : Colors.blue,
                                        decorationColor: player == PlayerColor.red ? Colors.red : Colors.blue,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star_border,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        4.0.spaceX,
                                        Text(
                                          playerRating != null ? '$playerRating' : '1200',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      opponentUsername,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: opponentPlayer == PlayerColor.red ? Colors.red : Colors.blue,
                                        decorationColor: opponentPlayer == PlayerColor.red ? Colors.red : Colors.blue,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          opponentRating != null ? '$opponentRating' : '1200',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        4.0.spaceX,
                                        const Icon(
                                          Icons.star_border,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                8.0.spaceX,
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: !isPlayerTurn
                                          ? opponentPlayer == PlayerColor.red
                                              ? Colors.red
                                              : Colors.blue
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: UsernameAvatar(
                                    username: opponentUsername,
                                    imageUrl: opponentPhotoUrl,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        10.0.spaceY,
                      ],
                      const SizedBox(height: 10),
                      KeyedSubtree(
                        key: _opponentCardsKey,
                        child: _buildHands(
                          opponentPlayer,
                          opponentTimeRemaining,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: KeyedSubtree(
                            key: _boardKey,
                            child: BoardWidget(
                              gameState: _gameState!,
                              onCellTap: _onCellTap,
                              playerColor: widget.isHost! ? PlayerColor.blue : PlayerColor.red,
                            ),
                          ),
                        ),
                      ),
                      KeyedSubtree(
                        key: _playerCardsKey,
                        child: _buildHands(
                          player,
                          playerTimeRemaining,
                        ),
                      ),
                      const SizedBox(height: 10),
                      KeyedSubtree(
                        key: _reserveCardKey,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CardWidget(
                            card: _gameState!.reserveCard,
                            localizedName: _getLocalizedCardName(
                              context,
                              _gameState!.reserveCard.name,
                            ),
                            selectable: false,
                            invert: true,
                            color: Colors.green,
                            isReserve: true,
                            owner: PlayerColor.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
