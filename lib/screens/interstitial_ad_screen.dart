import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdScreen extends StatefulWidget {
  const InterstitialAdScreen({this.navigateTo, this.onFinished, super.key}) : assert(navigateTo != null || onFinished != null);

  final Widget? navigateTo;
  final FutureOr<void> Function()? onFinished;

  @override
  State<InterstitialAdScreen> createState() => _InterstitialAdScreenState();
}

class _InterstitialAdScreenState extends State<InterstitialAdScreen> {
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/1033173712'
          : Platform.isAndroid
              ? 'ca-app-pub-2104845541457905/7127440348'
              : 'ca-app-pub-2104845541457905/8205105339',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _showAd();
        },
        onAdFailedToLoad: (error) {
          _navigateToNextScreen();
        },
      ),
    );
  }

  void _showAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _navigateToNextScreen();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _navigateToNextScreen();
        },
      );
      _interstitialAd!.show();
    } else {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    if (widget.onFinished != null) {
      final callback = widget.onFinished!;
      Navigator.of(context).pop();
      Future.microtask(() => callback());
      return;
    }

    final destination = widget.navigateTo;
    if (destination != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
