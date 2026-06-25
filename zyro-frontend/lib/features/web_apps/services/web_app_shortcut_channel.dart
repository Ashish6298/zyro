import 'package:flutter/services.dart';

class WebAppShortcutChannel {
  static const MethodChannel _channel = MethodChannel('zyro/web_apps');

  static Future<Map<String, dynamic>> pinWebAppShortcut({
    required String id,
    required String name,
    required String url,
    String? iconPath,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'pinWebAppShortcut',
      {
        'id': id,
        'name': name,
        'url': url,
        'iconPath': iconPath,
      },
    );
    return result ?? const <String, dynamic>{};
  }

  static Future<String?> getInitialShortcutUrl() {
    return _channel.invokeMethod<String>('getInitialShortcutUrl');
  }

  static void listenForShortcutLaunches(void Function(String url) onLaunch) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'webAppShortcutLaunched') {
        final args = call.arguments;
        final url = args is Map ? args['url'] as String? : null;
        if (url != null && url.isNotEmpty) {
          onLaunch(url);
        }
      }
    });
  }
}
