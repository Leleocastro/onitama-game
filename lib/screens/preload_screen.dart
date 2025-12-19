import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/theme_manager.dart';
import 'menu_screen.dart';

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(seconds: 5);
  Timer? _navigationTimer;
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this, duration: _animationDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPreloadFlow();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _lottieController.dispose();
    super.dispose();
  }

  void _startPreloadFlow() {
    _lottieController
      ..reset()
      ..forward();
    _navigationTimer = Timer(_animationDuration, _navigateToMenu);
    unawaited(_primeAppResources());
  }

  Future<void> _primeAppResources() async {
    try {
      await SettingsService.instance.fetchTimerMillis();
      await ThemeManager.loadAllThemes();
    } catch (error) {
      debugPrint('Failed to load themes: $error');
      return;
    }

    if (!mounted) return;

    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    final imagePreloadFuture = ThemeManager.preloadAllThemeImages(
      navigatorContext,
      onProgress: (done, total) {
        if (!mounted) return;
      },
    );

    unawaited(
      imagePreloadFuture.catchError((error, stackTrace) {
        debugPrint('Failed to preload theme images: $error');
      }),
    );
  }

  Future<void> _navigateToMenu() async {
    if (!mounted) return;
    _navigationTimer?.cancel();
    unawaited(AudioService.instance.playNavigationSound());
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
                width: 150,
              ),
            ),
            Lottie.asset(
              'assets/lotties/kungfu.json',
              controller: _lottieController,
              animate: false,
            ),
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
