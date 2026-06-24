import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart';
import 'platform/background_player_channel.dart';

class BackgroundPlayerService {
  static InAppWebViewController? _activeController;
  static String? _activeTabId;
  static bool isEnabled = false;
  static bool _isBackground = false;
  static bool _serviceStarted = false;

  // Media state fields
  static String? tabId;
  static String? pageUrl;
  static String? title;
  static String? mediaTitle;
  static bool isPlaying = false;
  static bool isPaused = true;
  static double currentTime = 0.0;
  static double duration = 0.0;
  static String? thumbnail;
  static String? sourceWebsite;
  static String? nextTitle;

  static void setActiveController(
    String tabId,
    InAppWebViewController? controller,
  ) {
    _activeTabId = tabId;
    _activeController = controller;
    if (controller != null) {
      _setupJavaScriptHandler(controller);
    }
  }

  static void initializeChannelHandler() {
    BackgroundPlayerChannel.setMethodCallHandler((MethodCall call) async {
      print(
        "[BACKGROUND PLAYER SERVICE] Received method call: ${call.method} from native platform.",
      );
      if (_activeController == null) return;

      switch (call.method) {
        case "play":
          await _activeController?.evaluateJavascript(
            source: """
            (function() {
              var media = document.querySelector('video, audio');
              if (media) {
                media.play();
              }
            })();
          """,
          );
          break;
        case "pause":
          await _activeController?.evaluateJavascript(
            source: """
            (function() {
              var media = document.querySelector('video, audio');
              if (media) {
                media.pause();
              }
            })();
          """,
          );
          break;
        case "next":
          await _activeController?.evaluateJavascript(
            source: """
            (function() {
              var nextBtn = document.querySelector('.ytp-next-button') || 
                            document.querySelector('[data-testid="control-button-skip-forward"]') || 
                            document.querySelector('.next-button') ||
                            document.querySelector('[aria-label="Next"]') ||
                            document.querySelector('.skip-next');
              if (nextBtn) {
                nextBtn.click();
              }
            })();
          """,
          );
          break;
        case "previous":
          await _activeController?.evaluateJavascript(
            source: """
            (function() {
              var prevBtn = document.querySelector('.ytp-prev-button') || 
                            document.querySelector('[data-testid="control-button-skip-back"]') || 
                            document.querySelector('.prev-button') ||
                            document.querySelector('[aria-label="Previous"]') ||
                            document.querySelector('.skip-previous');
              if (prevBtn) {
                prevBtn.click();
              } else {
                var media = document.querySelector('video, audio');
                if (media) {
                  media.currentTime = 0;
                }
              }
            })();
          """,
          );
          break;
        case "seekTo":
          final args = Map<String, dynamic>.from(call.arguments);
          final posMs = args['positionMs'] as int?;
          if (posMs != null) {
            final posSec = posMs / 1000.0;
            await _activeController?.evaluateJavascript(
              source:
                  """
              (function() {
                var media = document.querySelector('video, audio');
                if (media) {
                  media.currentTime = $posSec;
                }
              })();
            """,
            );
          }
          break;
      }
    });
  }

  static void _setupJavaScriptHandler(InAppWebViewController controller) {
    controller.removeJavaScriptHandler(handlerName: 'backgroundPlayerState');
    controller.addJavaScriptHandler(
      handlerName: 'backgroundPlayerState',
      callback: (args) {
        final data = Map<String, dynamic>.from(args[0]);
        tabId = _activeTabId;
        pageUrl = data['pageUrl'] ?? '';
        title = data['title'] ?? 'Playing in Zyro Browser';
        mediaTitle = data['mediaTitle'] ?? title;
        isPlaying = data['isPlaying'] == true;
        isPaused = data['isPaused'] == true;
        currentTime = (data['currentTime'] ?? 0.0).toDouble();
        duration = (data['duration'] ?? 0.0).toDouble();
        thumbnail = data['thumbnail'] ?? '';
        sourceWebsite = data['sourceWebsite'] ?? '';
        nextTitle = data['nextTitle'] ?? '';

        print(
          "[BACKGROUND PLAYER EVENT] title: $title, source: $sourceWebsite, isPlaying: $isPlaying",
        );

        if (isEnabled) {
          if (!_serviceStarted) {
            BackgroundPlayerChannel.startService(
              title: mediaTitle ?? 'Playing in Zyro Browser',
              website: sourceWebsite ?? 'Zyro Browser',
              isPlaying: isPlaying,
              positionMs: (currentTime * 1000).toInt(),
              durationMs: (duration * 1000).toInt(),
              nextTitle: nextTitle,
            );
            _serviceStarted = true;
          } else {
            BackgroundPlayerChannel.updateState(
              isPlaying: isPlaying,
              title: mediaTitle ?? 'Playing in Zyro Browser',
              website: sourceWebsite ?? 'Zyro Browser',
              positionMs: (currentTime * 1000).toInt(),
              durationMs: (duration * 1000).toInt(),
              nextTitle: nextTitle,
            );
          }
        }
      },
    );
  }

  static Future<void> injectMediaDetector(
    InAppWebViewController controller,
  ) async {
    await controller.evaluateJavascript(
      source: """
      (function() {
        try {
          Object.defineProperty(document, 'hidden', { value: false, writable: false });
          Object.defineProperty(document, 'visibilityState', { value: 'visible', writable: false });
          Object.defineProperty(document, 'webkitHidden', { value: false, writable: false });
        } catch(e) {}

        document.addEventListener('visibilitychange', function(e) {
          e.stopImmediatePropagation();
        }, true);
        document.addEventListener('webkitvisibilitychange', function(e) {
          e.stopImmediatePropagation();
        }, true);

        if (window.zyroBackgroundPlayerStarted) return;
        window.zyroBackgroundPlayerStarted = true;

        function getThumbnail() {
          var video = document.querySelector('video');
          if (video && video.poster) return video.poster;
          var ogImg = document.querySelector('meta[property="og:image"]');
          if (ogImg && ogImg.content) return ogImg.content;
          var twImg = document.querySelector('meta[name="twitter:image"]');
          if (twImg && twImg.content) return twImg.content;
          return '';
        }

        function getMediaSessionMetadata() {
          if (navigator.mediaSession && navigator.mediaSession.metadata) {
            return {
              title: navigator.mediaSession.metadata.title || '',
              artist: navigator.mediaSession.metadata.artist || '',
              album: navigator.mediaSession.metadata.album || ''
            };
          }
          return null;
        }

        function notifyState(media, isPlaying) {
          var docTitle = document.title || "Playing in Zyro Browser";
          docTitle = docTitle.replace(" - YouTube", "");
          
          var songTitle = docTitle;
          var artist = window.location.hostname.replace('www.', '');
          
          var meta = getMediaSessionMetadata();
          if (meta) {
            if (meta.title) songTitle = meta.title;
            if (meta.artist) artist = meta.artist;
          }
          
          window.flutter_inappwebview.callHandler('backgroundPlayerState', {
            'pageUrl': window.location.href,
            'title': songTitle,
            'mediaTitle': songTitle,
            'isPlaying': isPlaying,
            'isPaused': !isPlaying,
            'currentTime': isNaN(media.currentTime) ? 0 : media.currentTime,
            'duration': isNaN(media.duration) ? 0 : media.duration,
            'thumbnail': getThumbnail(),
            'sourceWebsite': artist,
            'nextTitle': ''
          });
        }

        function setupListeners(media) {
          if (media.zyroListenersAttached) return;
          media.zyroListenersAttached = true;

          media.addEventListener('play', function() {
            notifyState(media, true);
          });

          media.addEventListener('pause', function() {
            notifyState(media, false);
          });

          media.addEventListener('ended', function() {
            notifyState(media, false);
          });
        }

        setInterval(function() {
          var medias = document.querySelectorAll('video, audio');
          medias.forEach(function(media) {
            setupListeners(media);
            if (!media.paused) {
              notifyState(media, true);
            }
          });
        }, 1000);
      })();
    """,
    );
  }

  static void handleTabClosed(String closedTabId) {
    if (_activeTabId == closedTabId) {
      _activeTabId = null;
      _activeController = null;
      isPlaying = false;
      isPaused = true;
      _serviceStarted = false;
      BackgroundPlayerChannel.stopService();
    }
  }

  static void handleAppMinimized(bool enabled) {
    isEnabled = enabled;
    _isBackground = true;
    print(
      "[BACKGROUND PLAYER] handleAppMinimized. isEnabled: $isEnabled, isPlaying: $isPlaying",
    );

    if (!isEnabled) {
      BackgroundPlayerChannel.stopService();
      _serviceStarted = false;
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        _activeController?.resume();
        print(
          "[BACKGROUND PLAYER] Called activeController.resume() to keep playback alive in background.",
        );
      });
    }
  }

  static void handleAppResumed() {
    _isBackground = false;
    print("[BACKGROUND PLAYER] App resumed. Keeping service running.");
  }

  static void handleExtensionDisabled() {
    if (isEnabled) {
      isEnabled = false;
      _serviceStarted = false;
      BackgroundPlayerChannel.stopService();
      print("[BACKGROUND PLAYER] Extension disabled. Stopped service.");
    }
  }
}
