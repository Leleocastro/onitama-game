import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';

void main() => runApp(const OnitamaApp());

class OnitamaApp extends StatelessWidget {
  const OnitamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onitama - Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const MenuScreen(),
    );
  }
}