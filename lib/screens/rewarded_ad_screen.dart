import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdScreen extends StatefulWidget {
  final VoidCallback onReward;
  final Widget? navigateTo;

  const RewardedAdScreen({
    required this.onReward,
    this.navigateTo,
    super.key,
  });

  @override
  State<RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends State<RewardedAdScreen> {
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/5224354917'
          : Platform.isAndroid
              ? 'ca-app-pub-2104845541457905/7127440348'
              : 'ca-app-pub-2104845541457905/8205105339',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _showAd();
        },
        onAdFailedToLoad: (error) {
          _navigateToNextScreen();
        },
      ),
    );
  }

  void _showAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _navigateToNextScreen();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _navigateToNextScreen();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          widget.onReward();
        },
      );
    } else {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (widget.navigateTo != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.navigateTo!),
      );
    } else {
      // Apenas volta para a tela anterior mantendo o estado atual
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
