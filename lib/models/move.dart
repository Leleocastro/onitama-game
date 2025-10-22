import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/point.dart';

class Move {
  final Point from;
  final Point to;
  final CardModel card;

  Move(this.from, this.to, this.card);

  Map<String, dynamic> toMap() {
    return {
      'from': {'r': from.r, 'c': from.c},
      'to': {'r': to.r, 'c': to.c},
      'card': {
        'name': card.name,
        'moves': card.moves.map((move) => {'r': move.r, 'c': move.c}).toList(),
        'color': card.color.value,
      },
    };
  }

  factory Move.fromMap(Map<String, dynamic> map) {
    return Move(
      Point(map['from']['r'], map['from']['c']),
      Point(map['to']['r'], map['to']['c']),
      CardModel(
        map['card']['name'],
        (map['card']['moves'] as List).map((move) => Point(move['r'], move['c'])).toList(),
        Color(map['card']['color']),
      ),
    );
  }
}