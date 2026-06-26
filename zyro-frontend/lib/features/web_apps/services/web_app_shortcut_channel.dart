import 'package:flutter/services.dart';

class PinnedShortcutIdsResult {
  final bool supported;
  final List<String> ids;

  const PinnedShortcutIdsResult({required this.supported, required this.ids});
}

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
      {'id': id, 'name': name, 'url': url, 'iconPath': iconPath},
    );
    return result ?? const <String, dynamic>{};
  }

  static Future<PinnedShortcutIdsResult> getPinnedShortcutIds() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getPinnedShortcutIds',
    );
    if (result == null) {
      return const PinnedShortcutIdsResult(supported: false, ids: []);
    }
    final ids = (result['ids'] as List?)?.whereType<String>().toList() ?? [];
    return PinnedShortcutIdsResult(
      supported: result['supported'] == true,
      ids: ids,
    );
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
