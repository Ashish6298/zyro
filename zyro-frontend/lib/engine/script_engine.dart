import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'hooks.dart';

import '../features/video_downloader/services/video_detection_service.dart';

class ScriptEngine implements BrowserHooks {
  bool isAdBlockerEnabled = false;
  bool isVideoDownloaderEnabled = false;

  String get videoDownloaderScript => VideoDetectionService().detectionScript;

  final String _adBlockScript = """

    (function() {
        const hideAds = () => {
            const adSelectors = [
                '.video-ads', '.ytp-ad-module', '.ytp-ad-overlay-container',
                'ytd-promoted-video-renderer', 'ytd-display-ad-renderer',
                '#player-ads', '#masthead-ad', '.ad-container', '.ad-div',
                '#ad-slot', '.ad-unit', 'ins.adsbygoogle'
            ];
            adSelectors.forEach(selector => {
                document.querySelectorAll(selector).forEach(el => {
                  el.style.setProperty('display', 'none', 'important');
                });
            });

            // Skip YouTube video ads
            const skipBtn = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern');
            if (skipBtn) {
                skipBtn.click();
            }

            // Fast forward through ads
            const video = document.querySelector('video');
            if (document.querySelector('.ad-showing')) {
                if (video && video.playbackRate < 10) video.playbackRate = 16;
            } else {
                if (video && video.playbackRate > 2) video.playbackRate = 1;
            }
        };
        if (!window.zyroAdBlockerStarted) {
            window.zyroAdBlockerStarted = true;
            setInterval(hideAds, 500);
        }
    })();
  """;

  @override
  Future<void> onPageStart(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, _adBlockScript);
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, videoDownloaderScript);
    }
  }

  @override
  Future<void> onPageFinished(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, _adBlockScript);
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, videoDownloaderScript);
    }
  }

  @override
  Future<void> onUrlChanged(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, _adBlockScript);
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
