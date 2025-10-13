import 'package:flutter/material.dart';
import '../logic/game_state.dart';
import '../models/card_model.dart';
import '../models/player.dart';
import '../widgets/board_widget.dart';
import '../widgets/card_widget.dart';

class OnitamaHome extends StatefulWidget {
  const OnitamaHome({super.key});

  @override
  OnitamaHomeState createState() => OnitamaHomeState();
}

class OnitamaHomeState extends State<OnitamaHome> {
  late GameState _gameState;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
  }

  void _onCellTap(int r, int c) {
    setState(() {
      _gameState.onCellTap(r, c, _showEndDialog);
    });
  }

  void _onCardTap(CardModel card) {
    setState(() {
      _gameState.onCardTap(card);
    });
  }

  void _showEndDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(text),
        actions: [
          TextButton(
            child: const Text('Restart'),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _gameState.restart();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHands(PlayerColor player) {
    final hand = player == PlayerColor.red ? _gameState.redHand : _gameState.blueHand;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: hand
              .map((c) => CardWidget(
                    card: c,
                    isSelected: _gameState.selectedCardForMove?.name == c.name,
                    onTap: _onCardTap,
                    invert: player == PlayerColor.blue,
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_gameState.message),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _gameState.restart();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildHands(PlayerColor.red)),
          Expanded(child: Center(child: BoardWidget(gameState: _gameState, onCellTap: _onCellTap))),
          Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildHands(PlayerColor.blue)),
          const Text('Reserve'),
          CardWidget(
            card: _gameState.reserveCard,
            selectable: false,
          ),
        ],
      ),
    );
  }
}
