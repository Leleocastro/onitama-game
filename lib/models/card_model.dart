import 'package:flutter/material.dart';
import './point.dart';

class CardModel {
  final String name;
  final List<Point> moves;
  final Color color;
  CardModel(this.name, this.moves, this.color);
}
