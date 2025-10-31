import 'package:firebase_analytics/firebase_analytics.dart';

/// Lightweight helper around Firebase Analytics shared instance.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalytics get instance => _analytics;

  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> logScreenView(String screenName) => _analytics.logScreenView(screenName: screenName, screenClass: screenName);

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) =>
      _analytics.logEvent(name: name, parameters: parameters);
}
