import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onitama/firebase_options.dart';

import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const OnitamaApp());
}

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
