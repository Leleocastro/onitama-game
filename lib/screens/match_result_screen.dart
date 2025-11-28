import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../l10n/app_localizations.dart';
import '../models/match_result.dart';
import '../services/audio_service.dart';
import '../utils/extensions.dart';
import '../widgets/counter_points.dart';
import '../widgets/move_down_widget.dart';

class MatchResultScreen extends StatefulWidget {
  const MatchResultScreen({
    required this.result,
    required this.participant,
    required this.onExitToMenu,
    super.key,
  });

  final MatchResult result;
  final MatchParticipantResult participant;
  final VoidCallback onExitToMenu;

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  bool _compositionReady = false;
  bool _delayElapsed = false;
  bool _hasPlayed = false;

  bool get _isVictory => widget.result.winnerColor == widget.participant.color;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this, value: _isVictory ? 0 : 1);
    Future<void>.delayed(const Duration(seconds: 1)).then((_) {
      if (!mounted) return;
      _delayElapsed = true;
      _tryPlayAnimation();

      AudioService.instance.playSpecialWinSound();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  void _onCompositionLoaded(LottieComposition composition) {
    _lottieController.duration = composition.duration;
    _compositionReady = true;
    _tryPlayAnimation();
  }

  void _tryPlayAnimation() {
    if (_hasPlayed || !_compositionReady || !_delayElapsed) {
      return;
    }
    _hasPlayed = true;
    if (_isVictory) {
      _lottieController
        ..value = 0
        ..forward();
    } else {
      _lottieController
        ..value = 1
        ..reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratingDelta = widget.participant.ratingDelta;
    final displayDelta = ratingDelta.abs();
    final theme = Theme.of(context);
    final accentColor = ratingDelta >= 0 ? theme.colorScheme.secondary : theme.colorScheme.error;

    return WillPopScope(
      onWillPop: () async {
        widget.onExitToMenu();
        return true;
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isVictory ? const [Color(0xFF0F1E1A), Color(0xFF1D3A2C)] : const [Color(0xFF1E1010), Color(0xFF3B1F1F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onExitToMenu();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 24, left: 24, bottom: 32),
                    child: Column(
                      children: [
                        MoveDownWidget(
                          height: context.height * 0.2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset(
                                'assets/lotties/star.json',
                                controller: _lottieController,
                                repeat: false,
                                animate: false,
                                onLoaded: _onCompositionLoaded,
                                height: 110,
                              ),
                              Text(
                                _isVictory ? l10n.matchResultVictoryTitle : l10n.matchResultDefeatTitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.participant.username ?? l10n.you,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              CounterPoints(
                                value: displayDelta,
                                color: accentColor,
                                durationToStart: const Duration(milliseconds: 200),
                                leftWidget: Text(
                                  ratingDelta >= 0 ? '+' : '-',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                ratingDelta > 0
                                    ? l10n.matchResultGainedPoints(displayDelta)
                                    : ratingDelta < 0
                                        ? l10n.matchResultLostPoints(displayDelta)
                                        : l10n.matchResultNoChange,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RatingCard(
                                      label: l10n.matchResultPreviousRating,
                                      value: widget.participant.previousRating.toString(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RatingCard(
                                      label: l10n.matchResultNewRating,
                                      value: widget.participant.newRating.toString(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _InfoChip(
                                label: l10n.matchResultTierLabel,
                                value: _tierLabel(
                                  l10n,
                                  widget.participant.tier,
                                ),
                              ),
                              // Wrap(
                              //   spacing: 12,
                              //   runSpacing: 12,
                              //   alignment: WrapAlignment.center,
                              //   children: [
                              //     if (widget.participant.season.isNotEmpty)
                              //       _InfoChip(
                              //         label: l10n.matchResultSeasonLabel,
                              //         value: widget.participant.season,
                              //       ),
                              //     _InfoChip(
                              //       label: 'K',
                              //       value: widget.participant.kFactor.toString(),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tierLabel(AppLocalizations l10n, String value) {
    switch (value.toLowerCase()) {
      case 'bronze':
        return l10n.leaderboardTierBronze;
      case 'silver':
        return l10n.leaderboardTierSilver;
      case 'gold':
        return l10n.leaderboardTierGold;
      case 'platinum':
        return l10n.leaderboardTierPlatine;
      case 'diamond':
        return l10n.leaderboardTierDiamond;
      default:
        return value.isEmpty ? '-' : value;
    }
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
