import 'package:flutter/material.dart';

import '../models/move.dart';

class HistoricGameDetailScreen extends StatelessWidget {
  final List<Move> moves;

  const HistoricGameDetailScreen({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Game History'),
      ),
      body: ListView.builder(
        itemCount: moves.length,
        itemBuilder: (context, index) {
          final move = moves[index];
          return ListTile(
            title: Text('Move ${index + 1}'),
            subtitle: Text('From: (${move.from.r}, ${move.from.c}) To: (${move.to.r}, ${move.to.c}) with ${move.card.name}'),
          );
        },
      ),
    );
  }
}
