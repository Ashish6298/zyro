import 'package:shared_preferences/shared_preferences.dart';

class ScreenshotProSettingsService {
  static const _key = 'zyro_screenshot_pro_enabled';
  Future<bool> loadEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;
  Future<void> saveEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(_key, enabled);
}
