import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'hooks.dart';

import '../features/video_downloader/services/video_detection_service.dart';
import '../features/extensions/ad_blocker/services/youtube_ad_blocker_service.dart';
import '../features/extensions/ad_blocker/services/cosmetic_filter_injector.dart';

class ScriptEngine implements BrowserHooks {
  bool isAdBlockerEnabled = false;
  bool isVideoDownloaderEnabled = false;

  String get videoDownloaderScript => VideoDetectionService().detectionScript;

  String getInjectedScript(String urlString) {
    final isYouTube = urlString.contains('youtube.com') || urlString.contains('youtu.be');
    if (isYouTube) {
      return YouTubeAdBlockerService.cosmeticScript;
    } else {
      return CosmeticFilterInjector.cosmeticScript;
    }
  }

  @override
  Future<void> onPageStart(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, getInjectedScript(url?.toString() ?? ''));
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, videoDownloaderScript);
    }
  }

  @override
  Future<void> onPageFinished(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, getInjectedScript(url?.toString() ?? ''));
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, videoDownloaderScript);
    }
  }

  @override
  Future<void> onUrlChanged(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, getInjectedScript(url?.toString() ?? ''));
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, videoDownloaderScript);
    }
  }

  @override
  Future<void> onProgressChanged(InAppWebViewController controller, int progress) async {}

  Future<void> executeManualScript(InAppWebViewController controller, String source) async {
    await controller.evaluateJavascript(source: source);
  }
}
