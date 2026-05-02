import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'hooks.dart';

class ScriptEngine implements BrowserHooks {
  bool isAdBlockerEnabled = false;
  bool isVideoDownloaderEnabled = false;

  String get videoDownloaderScript => _videoDownloaderScript;

  final String _videoDownloaderScript = """
    (function() {
        console.log('Zyro: Video Downloader script starting...');
        const injectDownloader = () => {
            const isYouTube = window.location.hostname.includes('youtube.com');
            const videos = Array.from(document.querySelectorAll('video'));
            
            // Look for the most likely active video
            let activeVideo = null;
            if (isYouTube) {
                activeVideo = document.querySelector('.html5-main-video') || 
                              document.querySelector('video.video-stream') ||
                              videos.find(v => v.src || v.currentSrc);
            } else {
                activeVideo = videos.find(v => v.offsetWidth > 0 && v.offsetHeight > 0) || videos[0];
            }

            let downloadBtn = document.getElementById('zyro-video-downloader');
            
            if (activeVideo && (activeVideo.src || activeVideo.currentSrc)) {
                if (!downloadBtn) {
                    console.log('Zyro: Video detected, injecting button');
                    downloadBtn = document.createElement('div');
                    downloadBtn.id = 'zyro-video-downloader';
                    downloadBtn.textContent = '▼'; // Download-like symbol
                    
                    // Add animation styles
                    const styleSheet = document.createElement('style');
                    styleSheet.textContent = `
                        @keyframes zyro-pulse {
                            0% { transform: scale(1); box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
                            70% { transform: scale(1.1); box-shadow: 0 0 0 15px rgba(239, 68, 68, 0); }
                            100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
                        }
                    `;
                    document.head.appendChild(styleSheet);

                    Object.assign(downloadBtn.style, {
                        position: 'fixed',
                        bottom: '120px',
                        right: '20px',
                        width: '60px',
                        height: '60px',
                        backgroundColor: '#ef4444', // Red color
                        borderRadius: '50%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '32px',
                        color: 'white',
                        cursor: 'pointer',
                        zIndex: '2147483647',
                        animation: 'zyro-pulse 2s infinite',
                        border: '3px solid rgba(255, 255, 255, 0.5)',
                        userSelect: 'none',
                        webkitUserSelect: 'none'
                    });
                    
                    downloadBtn.onclick = (e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        console.log('Zyro: Download button clicked');
                        const pageUrl = window.location.href;
                        const videoUrl = activeVideo.src || activeVideo.currentSrc || pageUrl;
                        window.flutter_inappwebview.callHandler('triggerDownload', {
                            url: isYouTube ? pageUrl : videoUrl,
                            sourceUrl: videoUrl,
                            pageUrl: pageUrl,
                            isYouTube: isYouTube,
                            title: document.title
                        });
                    };
                    
                    document.body.appendChild(downloadBtn);
                }
            } else {
                if (downloadBtn) {
                    console.log('Zyro: No video found, removing button');
                    downloadBtn.remove();
                }
            }
        };

        if (!window.zyroVideoDownloaderStarted) {
            window.zyroVideoDownloaderStarted = true;
            setInterval(injectDownloader, 500); // Check more frequently
            injectDownloader();
        }
    })();
  """;

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
      await executeManualScript(controller, _videoDownloaderScript);
    }
  }

  @override
  Future<void> onPageFinished(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, _adBlockScript);
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, _videoDownloaderScript);
    }
  }

  @override
  Future<void> onUrlChanged(InAppWebViewController controller, WebUri? url) async {
    if (isAdBlockerEnabled) {
      await executeManualScript(controller, _adBlockScript);
    }
    if (isVideoDownloaderEnabled) {
      await executeManualScript(controller, _videoDownloaderScript);
    }
  }

  @override
  Future<void> onProgressChanged(InAppWebViewController controller, int progress) async {}

  Future<void> executeManualScript(InAppWebViewController controller, String source) async {
    await controller.evaluateJavascript(source: source);
  }
}
