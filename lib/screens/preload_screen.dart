import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../l10n/app_localizations.dart';
import '../services/theme_manager.dart';
import 'menu_screen2.dart';

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> with SingleTickerProviderStateMixin {
  int _total = 1;
  String _status = '';
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThemeAndImages();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
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
          _total = total;
          _status = l10n.preloadDownloadingImages(done, total);
        });
        _syncAnimationWithProgress(done, total);
      },
    );
    setState(() {
      _status = l10n.preloadDone;
    });
    _syncAnimationWithProgress(_total, _total);
    await Future.delayed(const Duration(milliseconds: 500));

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MenuScreen2()),
    );
  }

  void _syncAnimationWithProgress(int done, int total) {
    final safeTotal = total == 0 ? 1 : total;
    final progress = (done / safeTotal).clamp(0.0, 1.0);
    _lottieController.animateTo(
      progress,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
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
                width: 150,
              ),
            ),
            Lottie.asset(
              'assets/lotties/kungfu.json',
              controller: _lottieController,
              animate: false,
              onLoaded: (composition) {
                _lottieController.duration = composition.duration;
              },
            ),
            const SizedBox(height: 16),
            Text(_status),
            if (_total > 1) Text(AppLocalizations.of(context)!.preloadImagesCount(_total)),
          ],
        ),
      ),
    );
  }
}

Future<LottieComposition?> customDecoder(List<int> bytes) {
  return LottieComposition.decodeZip(
    bytes,
    filePicker: (files) {
      return files.firstWhere(
        (f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
      );
    },
  );
}
