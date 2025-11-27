import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/leaderboard_entry.dart';
import '../services/ranking_service.dart';
import 'username_avatar.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({required this.playerUid, super.key});
  final String playerUid;

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final RankingService _rankingService = RankingService();

  String? _playerUid;

  @override
  void initState() {
    super.initState();
    _playerUid = widget.playerUid;
  }

  @override
  Widget build(BuildContext context) {
    return _buildLeaderboardSection();
  }

  Widget _buildLeaderboardSection() {
    if (_playerUid == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Card(
        margin: const EdgeInsets.only(top: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${entry.rank ?? '-'}', style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(width: 8),
                                  UsernameAvatar(
                                    username: entry.username,
                                    size: 32,
                                    tooltip: entry.username,
                                    imageUrl: entry.photoUrl,
                                  ),
                                ],
                              ),
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
