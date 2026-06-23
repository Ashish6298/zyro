import 'package:flutter/services.dart';

class FloatingVideoChannel {
  static const MethodChannel _channel = MethodChannel('zyro/floating_video');
  static void Function(bool)? onPipModeChangedCallback;

  // Debouncing parameters
  static bool? _lastIsPlaying;
  static int? _lastVideoWidth;
  static int? _lastVideoHeight;
  static String? _lastVideoTitle;
  static String? _lastPageUrl;
  static bool? _lastFloatingVideoEnabled;

  static void initialize() {
    _channel.setMethodCallHandler((MethodCall call) async {
      print("[FLOATING VIDEO CHANNEL] Received native call: ${call.method}");
      switch (call.method) {
        case "onPipModeChanged":
          final active = call.arguments as bool;
          if (active) {
            print("onPipModeChanged(true) received in Flutter");
          } else {
            print("onPipModeChanged(false) received in Flutter");
          }
          if (onPipModeChangedCallback != null) {
            onPipModeChangedCallback!(active);
          }
          break;
      }
    });
  }

  static Future<bool> enterPictureInPicture() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('enterPipMode');
      return result ?? false;
    } on MissingPluginException catch (_) {
      print("[FLOATING VIDEO CHANNEL] enterPipMode not implemented on native side yet.");
      return false;
    } catch (e) {
      print("[FLOATING VIDEO CHANNEL ERROR] Failed to enter PiP: $e");
      return false;
    }
  }

  static Future<bool> isPictureInPictureSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } on MissingPluginException catch (_) {
      print("[FLOATING VIDEO CHANNEL] isPipSupported not implemented on native side yet.");
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setVideoPlaying(
    bool isPlaying, {
    int videoWidth = 0,
    int videoHeight = 0,
    String videoTitle = "",
    String pageUrl = "",
    double duration = 0.0,
    double currentTime = 0.0,
    bool isVisible = true,
  }) async {
    if (_lastIsPlaying == isPlaying &&
        _lastVideoWidth == videoWidth &&
        _lastVideoHeight == videoHeight &&
        _lastVideoTitle == videoTitle &&
        _lastPageUrl == pageUrl) {
      print("setVideoPlaying skipped because state unchanged");
      return;
    }

    _lastIsPlaying = isPlaying;
    _lastVideoWidth = videoWidth;
    _lastVideoHeight = videoHeight;
    _lastVideoTitle = videoTitle;
    _lastPageUrl = pageUrl;

    try {
      await _channel.invokeMethod('setVideoPlaying', {
        'isPlaying': isPlaying,
        'videoWidth': videoWidth,
        'videoHeight': videoHeight,
        'videoTitle': videoTitle,
        'pageUrl': pageUrl,
        'duration': duration,
        'currentTime': currentTime,
        'isVisible': isVisible,
      });
    } on MissingPluginException catch (_) {
      print("[FLOATING VIDEO CHANNEL] setVideoPlaying not implemented on native side yet.");
    } catch (e) {
      print("[FLOATING VIDEO CHANNEL ERROR] Failed to set video playing state: $e");
    }
  }

  static Future<void> setFloatingVideoEnabled(bool enabled) async {
    if (_lastFloatingVideoEnabled == enabled) {
      print("setFloatingVideoEnabled skipped because state unchanged");
      return;
    }
    _lastFloatingVideoEnabled = enabled;

    try {
      await _channel.invokeMethod('setFloatingVideoEnabled', {'enabled': enabled});
    } on MissingPluginException catch (_) {
      print("[FLOATING VIDEO CHANNEL] setFloatingVideoEnabled not implemented on native side yet.");
    } catch (e) {
      print("[FLOATING VIDEO CHANNEL ERROR] Failed to set extension enabled state: $e");
    }
  }
}

