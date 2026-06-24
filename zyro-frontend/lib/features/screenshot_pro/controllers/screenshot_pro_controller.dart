import 'package:flutter/foundation.dart';
import '../services/screenshot_pro_settings_service.dart';

class ScreenshotProController extends ChangeNotifier {
  ScreenshotProController({ScreenshotProSettingsService? settings})
    : _settings = settings ?? ScreenshotProSettingsService() {
    _load();
  }
  final ScreenshotProSettingsService _settings;
  bool _enabled = false;
  bool _loaded = false;
  bool get enabled => _enabled;
  bool get loaded => _loaded;
  Future<void> _load() async {
    _enabled = await _settings.loadEnabled();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _settings.saveEnabled(value);
    if (kDebugMode)
      debugPrint('[SCREENSHOT PRO] ${value ? 'enabled' : 'disabled'}');
    notifyListeners();
  }
}
