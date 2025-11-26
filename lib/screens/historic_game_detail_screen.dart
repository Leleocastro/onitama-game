import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/move.dart';

class HistoricGameDetailScreen extends StatelessWidget {
  final List<Move> moves;

  const HistoricGameDetailScreen({required this.moves, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moveHistoryTitle, style: TextStyle(fontFamily: 'SpellOfAsia')),
      ),
      body: ListView.builder(
        itemCount: moves.length,
        itemBuilder: (context, index) {
          final move = moves[index];
          final moveTitle = l10n.moveHistoryMove(index + 1);
          final moveSubtitle = l10n.moveHistoryFromTo(move.card.name, move.from.c, move.from.r, move.to.c, move.to.r);
          return ListTile(
            title: Text(moveTitle),
            subtitle: Text(moveSubtitle),
          );
        },
      ),
    );
  }
}
