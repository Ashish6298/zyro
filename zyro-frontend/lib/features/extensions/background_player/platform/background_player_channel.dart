import 'package:flutter/services.dart';

class BackgroundPlayerChannel {
  static const MethodChannel _channel = MethodChannel('zyro/background_player');

  static Future<void> startService({
    required String title,
    required String website,
    required bool isPlaying,
    int? positionMs,
    int? durationMs,
    String? nextTitle,
  }) async {
    try {
      await _channel.invokeMethod('startService', {
        'title': title,
        'website': website,
        'isPlaying': isPlaying,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'nextTitle': nextTitle,
      });
    } on PlatformException catch (e) {
      print("[BACKGROUND PLAYER CHANNEL ERROR] Failed to start service: ${e.message}");
    }
  }

  static Future<void> updateState({
    required bool isPlaying,
    required String title,
    required String website,
    int? positionMs,
    int? durationMs,
    String? nextTitle,
  }) async {
    try {
      await _channel.invokeMethod('updateState', {
        'isPlaying': isPlaying,
        'title': title,
        'website': website,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'nextTitle': nextTitle,
      });
    } on PlatformException catch (e) {
      print("[BACKGROUND PLAYER CHANNEL ERROR] Failed to update state: ${e.message}");
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (e) {
      print("[BACKGROUND PLAYER CHANNEL ERROR] Failed to stop service: ${e.message}");
    }
  }

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call) handler) {
    _channel.setMethodCallHandler(handler);
  }
}
