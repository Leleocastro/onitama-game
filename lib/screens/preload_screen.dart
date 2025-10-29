import 'package:flutter/material.dart';

import '../services/theme_manager.dart';
import 'menu_screen.dart';

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> {
  int _done = 0;
  int _total = 1;
  String _status = 'Carregando tema...';

  @override
  void initState() {
    super.initState();
    _loadThemeAndImages();
  }

  Future<void> _loadThemeAndImages() async {
    setState(() {
      _status = 'Buscando temas disponíveis...';
    });
    await ThemeManager.loadAllThemes();
    setState(() {
      _status = 'Pré-carregando imagens...';
    });
    // Calcula total de imagens
    _total = ThemeManager.themes.values.fold(0, (acc, t) => acc + t.assets.length);
    await ThemeManager.preloadAllThemeImages(
      context,
      onProgress: (done, total) {
        setState(() {
          _done = done;
          _total = total;
          _status = 'Baixando imagens ($done/$total)...';
        });
      },
    );
    setState(() {
      _status = 'Concluído!';
    });
    await Future.delayed(const Duration(milliseconds: 500));

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/images/logo.png',
                width: 250,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
            if (_total > 1) Text('$_done/$_total imagens'),
          ],
        ),
      ),
    );
  }
}
