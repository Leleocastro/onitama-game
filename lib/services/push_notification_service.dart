import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Top-level background handler for FCM. Must be a top-level function.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    debugPrint('Handling a background message: ${message.messageId}');
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize FCM handlers and local notifications.
  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Initialize local notifications for foreground display (Android + iOS)
    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher_adaptive_fore');
    final initializationSettingsDarwin = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create a notification channel for Android (required for Android 8+)
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'default_channel', // id
        'Default', // title
        description: 'Default channel for notifications',
        importance: Importance.high,
      );
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }

    // Request permission for iOS (and Android 13+)
    final settingsMessaging = await FirebaseMessaging.instance.requestPermission();

    // Ensure notifications are presented when app is in foreground on iOS
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      FirebaseMessaging.instance.getToken().then((token) => debugPrint('FCM token: $token'));
      debugPrint('User granted permission: ${settingsMessaging.authorizationStatus}');
    }

    // Handle foreground messages and show local notification using the adaptive icon
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        // Android-specific details
        AndroidNotificationDetails? androidDetails;
        if (Platform.isAndroid) {
          androidDetails = AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default channel for notifications',
            icon: 'ic_launcher_adaptive_fore',
          );
        }

        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: androidDetails,
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });
  }

  /// Convenience: get FCM token for this device.
  static Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
