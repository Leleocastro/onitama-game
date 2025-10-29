import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  String _status = '';

  @override
  void initState() {
    super.initState();
    // schedule after first frame so localization delegates are available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadThemeAndImages());
  }

  Future<void> _loadThemeAndImages() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _status = l10n.preloadFetchingThemes;
    });
    await ThemeManager.loadAllThemes();
    setState(() {
      _status = l10n.preloadPreloadingImages;
    });
    // Calcula total de imagens
    _total = ThemeManager.themes.values.fold(0, (acc, t) => acc + t.assets.length);
    await ThemeManager.preloadAllThemeImages(
      context,
      onProgress: (done, total) {
        setState(() {
          _done = done;
          _total = total;
          _status = l10n.preloadDownloadingImages(done, total);
        });
      },
    );
    setState(() {
      _status = l10n.preloadDone;
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
            if (_total > 1) Text(AppLocalizations.of(context)!.preloadImagesCount(_total)),
          ],
        ),
      ),
    );
  }
}
