import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import '../l10n/app_localizations.dart';
import '../models/leaderboard_entry.dart';
import '../services/ranking_service.dart';
import '../style/theme.dart';
import '../utils/extensions.dart';
import '../widgets/username_avatar.dart';
import 'history_game_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({required this.playerUid, super.key});

  final String playerUid;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final RankingService _rankingService = RankingService();
  late File file;
  late RiveWidgetController controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    initRive();
  }

  Future<void> initRive() async {
    file = (await File.asset('assets/rive/animated-background.riv', riveFactory: Factory.rive))!;
    controller = RiveWidgetController(file);
    setState(() => isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          if (isInitialized)
            RiveWidget(
              controller: controller,
              fit: Fit.cover,
            ),
          StreamBuilder<List<LeaderboardEntry>>(
            stream: _rankingService.watchTopEntries(limit: 50),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? <LeaderboardEntry>[];
              final isLoading = snapshot.connectionState == ConnectionState.waiting && entries.isEmpty;
              final podiumEntries = entries.take(3).toList();
              final remainingEntries = entries.skip(3).toList();
              LeaderboardEntry? highlightedEntry;
              for (final entry in entries) {
                if (entry.userId == widget.playerUid) {
                  highlightedEntry = entry;
                  break;
                }
              }

              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  context.safeAreaTopPadding.spaceY,
                  _Header(l10n: l10n),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _PodiumSection(
                            entries: podiumEntries,
                            l10n: l10n,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                _PlayerSummaryCard(
                                  playerUid: widget.playerUid,
                                  highlightedEntry: highlightedEntry,
                                  rankingService: _rankingService,
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: remainingEntries.length,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemBuilder: (context, index) {
                                    final entry = remainingEntries[index];
                                    final isCurrentPlayer = entry.userId == widget.playerUid;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: index == remainingEntries.length - 1 ? context.bottomPadding : 12),
                                      child: _LeaderboardTile(
                                        entry: entry,
                                        isCurrentPlayer: isCurrentPlayer,
                                        l10n: l10n,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.textPrimary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.leaderboardTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontFamily: 'SpellOfAsia'),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   l10n.leaderboardInvite,
                //   style: Theme.of(context).textTheme.bodyMedium,
                //   textAlign: TextAlign.center,
                // ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryGameScreen(),
              ),
            ),
            icon: Image.asset(
              'assets/icons/history.png',
              width: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  const _PodiumSection({required this.entries, required this.l10n});

  final List<LeaderboardEntry> entries;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: _EmptyState(message: l10n.leaderboardEmpty),
      );
    }

    final podiumOrder = [1, 0, 2];
    final podiumHeights = [120.0, 170.0, 100.0];
    final podiumColors = [AppTheme.primaryLight, AppTheme.primary, AppTheme.accent];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (index) {
              final entryIndex = podiumOrder[index];
              final entry = entryIndex < entries.length ? entries[entryIndex] : null;
              final place = entryIndex + 1;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: podiumColors[index],
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: UsernameAvatar(
                        username: entry?.username ?? '',
                        size: place == 1 ? 48 : 36,
                        tooltip: entry?.username ?? '',
                        imageUrl: entry?.photoUrl,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry?.username ?? '--',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: podiumHeights[index],
                      width: 100,
                      decoration: BoxDecoration(
                        color: entry != null ? podiumColors[index] : Colors.grey.shade300,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Column(
                        children: [
                          FittedBox(
                            child: Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 30 / place * 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry != null ? '${entry.rating} pts' : '---',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              '#$place',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  const _PlayerSummaryCard({
    required this.playerUid,
    required this.highlightedEntry,
    required this.rankingService,
  });

  final String playerUid;
  final LeaderboardEntry? highlightedEntry;
  final RankingService rankingService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<LeaderboardEntry?>(
        stream: rankingService.watchPlayerEntry(playerUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LinearProgressIndicator();
          }
          final entry = snapshot.data;
          if (entry == null) {
            return _EmptyState(message: l10n.leaderboardInvite);
          }
          final winRate = (entry.winRate * 100).toStringAsFixed(0);
          final rankLabel = highlightedEntry?.rank != null ? '#${highlightedEntry!.rank!.toString().padLeft(2, '0')}' : '--';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                UsernameAvatar(
                  username: entry.username,
                  size: 48,
                  tooltip: entry.username,
                  imageUrl: entry.photoUrl,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.username,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.leaderboardPlayerSubtitle(
                          entry.rating,
                          _localizedTier(entry.tier, l10n),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rankLabel, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(l10n.leaderboardWinRateShort(winRate)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.isCurrentPlayer, required this.l10n});

  final LeaderboardEntry entry;
  final bool isCurrentPlayer;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final winRate = (entry.winRate * 100).toStringAsFixed(0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? Colors.white : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCurrentPlayer ? AppTheme.accent : Colors.transparent, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            entry.rank != null ? entry.rank!.toString().padLeft(2, '0') : '--',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: 16),
          UsernameAvatar(
            username: entry.username,
            size: 40,
            tooltip: entry.username,
            imageUrl: entry.photoUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_localizedTier(entry.tier, l10n)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.rating} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(l10n.leaderboardWinRateShort(winRate)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          const Icon(Icons.emoji_people_outlined, color: AppTheme.primaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
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
