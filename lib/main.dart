import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rive/rive.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/preload_screen.dart';
import 'services/analytics_service.dart';
import 'services/audio_service.dart';
import 'services/push_notification_service.dart';
import 'services/revenuecat_service.dart';
import 'services/route_observer.dart';
import 'style/theme.dart';

Future<void> main() async {
  FirebaseCrashlytics? crashlytics;

  // Push notifications are initialized in PushNotificationService

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await MobileAds.instance.initialize();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize push notifications (registers background handler, channels and listeners)
      await PushNotificationService.initialize();
      await RevenueCatService.instance.initialize();

      crashlytics = FirebaseCrashlytics.instance;
      await crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
      FlutterError.onError = crashlytics!.recordFlutterFatalError;

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        crashlytics!.recordError(error, stack, fatal: true);
        return true;
      };

      await AnalyticsService.instance.logAppOpen();
      final analyticsObserver = AnalyticsService.observer;

      await RiveNative.init();
      await AudioService.instance.initialize();

      runApp(OnitamaApp(analyticsObserver: analyticsObserver));
    },
    (error, stack) => (crashlytics ?? FirebaseCrashlytics.instance).recordError(error, stack, fatal: true),
  );
}

class OnitamaApp extends StatelessWidget {
  const OnitamaApp({
    required this.analyticsObserver,
    super.key,
  });

  final NavigatorObserver analyticsObserver;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onitama - Flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      navigatorObservers: [analyticsObserver, appRouteObserver],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('pt'), // Portuguese
      ],
      home: PreloadScreen(),
    );
  }
}
