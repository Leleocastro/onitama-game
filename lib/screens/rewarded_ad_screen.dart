import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdScreen extends StatefulWidget {
  const RewardedAdScreen({super.key});

  @override
  State<RewardedAdScreen> createState() => _RewardedAdScreenState();
}

class _RewardedAdScreenState extends State<RewardedAdScreen> {
  RewardedAd? _rewardedAd;
  bool _rewardEarned = false;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: kDebugMode
          ? 'ca-app-pub-3940256099942544/5224354917'
          : Platform.isAndroid
              ? 'ca-app-pub-2104845541457905/1852205857'
              : 'ca-app-pub-2104845541457905/8791991051',
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
      _adShown = true;
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _navigateToNextScreen();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _navigateToNextScreen();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          _rewardEarned = true;
        },
      );
    } else {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final result = _adShown ? _rewardEarned : null;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
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
