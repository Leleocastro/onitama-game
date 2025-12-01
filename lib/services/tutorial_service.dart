import 'package:shared_preferences/shared_preferences.dart';

/// Tutorial flows that are shown only once per installation.
enum TutorialFlow { menu, playMenu, gameplay }

class TutorialService {
  TutorialService._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<bool> shouldShow(TutorialFlow flow) async {
    final prefs = await _instance();
    return !(prefs.getBool(_key(flow)) ?? false);
  }

  static Future<void> markCompleted(TutorialFlow flow) async {
    final prefs = await _instance();
    await prefs.setBool(_key(flow), true);
  }

  static String _key(TutorialFlow flow) {
    switch (flow) {
      case TutorialFlow.menu:
        return 'tutorial_menu_seen';
      case TutorialFlow.playMenu:
        return 'tutorial_play_menu_seen';
      case TutorialFlow.gameplay:
        return 'tutorial_gameplay_seen';
    }
  }
}
