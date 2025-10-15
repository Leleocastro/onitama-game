
import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Onitama',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Onitama is a two-player abstract strategy game with a unique movement mechanic.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Objective',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'There are two ways to win:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            '1. Way of the Stone: Capture your opponent\'s Master pawn.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '2. Way of the Stream: Move your Master pawn to your opponent\'s starting Temple Arch space.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Setup',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '1. Each player starts with five pawns: one Master and four Students.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '2. Pawns are placed on the 5x5 board in their starting positions.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '3. Each player receives two random Move cards.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '4. One extra card is placed on the side of the board.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Gameplay',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'On your turn, you must perform the following steps:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 5),
          Text(
            '1. Choose one of your two Move cards.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '2. Move one of your pawns according to the selected card.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '3. The card you used is then exchanged with the card on the side of the board.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Movement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            '- The black square on a Move card represents the pawn\'s current position.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '- The colored squares show the possible moves from that position.',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            '- You cannot move a pawn off the board or onto a space occupied by your own pawn.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          Text(
            'Capturing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'If you move a pawn to a square occupied by an opponent\'s pawn, the opponent\'s pawn is captured and removed from the game.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
