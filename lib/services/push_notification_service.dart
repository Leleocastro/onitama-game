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

    // Initialize local notifications for foreground display
    const initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher_adaptive_fore');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Create a notification channel for Android (required for Android 8+)
    const channel = AndroidNotificationChannel(
      'default_channel', // id
      'Default', // title
      description: 'Default channel for notifications',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    // Request permission for iOS (and Android 13+)
    final settingsMessaging = await FirebaseMessaging.instance.requestPermission();

    if (kDebugMode) {
      FirebaseMessaging.instance.getToken().then((token) => debugPrint('FCM token: $token'));
      debugPrint('User granted permission: ${settingsMessaging.authorizationStatus}');
    }

    // Handle foreground messages and show local notification using the adaptive icon
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'ic_launcher_adaptive_fore',
            ),
          ),
        );
      }
    });
  }

  /// Convenience: get FCM token for this device.
  static Future<String?> getToken() => FirebaseMessaging.instance.getToken();
}
