import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'floating_video_models.dart';
import 'platform/floating_video_channel.dart';

enum FloatingVideoState {
  idle,
  videoDetected,
  waitingForMinimize,
  enteringPip,
  pipActive,
  pipExited,
  unsupported
}

enum BrowserRenderMode {
  normal,
  pipPreparing,
  pipActive,
}

class FloatingVideosController extends ChangeNotifier {
  FloatingVideoModel? _activeVideo;
  FloatingVideoState _state = FloatingVideoState.idle;
  BrowserRenderMode _renderMode = BrowserRenderMode.normal;
  
  double _opacity = 1.0;
  double _playbackRate = 1.0;
  
  double _width = 240.0;
  double _height = 135.0;
  
  double _positionX = 20.0;
  double _positionY = 100.0;
  
  InAppWebViewController? _webViewController;

  // --- Cached video dimensions for PiP transition protection ---
  // ignore: unused_field
  String _lastKnownVideoTitle = '';
  int _lastKnownVideoWidth = 0;
  int _lastKnownVideoHeight = 0;
  // ignore: unused_field
  double _lastKnownCurrentTime = 0.0;
  // ignore: unused_field
  double _lastKnownDuration = 0.0;
  // ignore: unused_field
  String _lastKnownVideoUrl = '';
  bool _lastKnownIsPlaying = false;
  // ignore: unused_field
  bool _lastKnownIsVisible = true;
  Map<String, dynamic> _lastKnownBoundingRect = {};

  // Transition window: ignore stale 0x0 reports during PiP entry
  DateTime? _pipTransitionStart;
  static const Duration _pipTransitionWindow = Duration(seconds: 3);

  FloatingVideosController() {
    FloatingVideoChannel.onPipModeChangedCallback = (active) async {
      if (active) {
        setRenderMode(BrowserRenderMode.pipActive);
        _pipTransitionStart = DateTime.now();
        updateState(FloatingVideoState.pipActive);
        await _injectPipCleanupScript();
        print("Cleanup reapplied after PiP start");
        print("Native video surface attached");
        print("PiP active");
        print("Flutter received pipActive=true");
      } else {
        // Restore DOM styles
        final controller = _webViewController;
        if (controller != null) {
          try {
            await controller.evaluateJavascript(source: """
              (function () {
                window.__zyroPipCleanupActive = false;

                if (window.__zyroPipCleanupInterval) {
                  clearInterval(window.__zyroPipCleanupInterval);
                  window.__zyroPipCleanupInterval = null;
                }

                document.documentElement.classList.remove('zyro-pip-video-only');

                document.getElementById('zyro-pip-video-only-style')?.remove();

                document
                  .querySelectorAll('[data-zyro-pip-video="true"]')
                  .forEach(v => v.removeAttribute('data-zyro-pip-video'));

                document
                  .querySelectorAll('[data-zyro-pip-ancestor="true"]')
                  .forEach(v => v.removeAttribute('data-zyro-pip-ancestor'));

                document.querySelectorAll('*').forEach(el => {
                  el.style.removeProperty('display');
                  el.style.removeProperty('visibility');
                  el.style.removeProperty('opacity');
                  el.style.removeProperty('pointer-events');
                  el.style.removeProperty('position');
                  el.style.removeProperty('top');
                  el.style.removeProperty('left');
                  el.style.removeProperty('width');
                  el.style.removeProperty('height');
                  el.style.removeProperty('object-fit');
                  el.style.removeProperty('background');
                  el.style.removeProperty('z-index');
                });
              })();
            """);
            print("Video-only DOM isolation restored");
            print("Normal browser UI restored");
          } catch (e) {
            print("Error restoring DOM styles: $e");
          }
        }

        setRenderMode(BrowserRenderMode.normal);
        print("PiP exited");
        print("Browser UI restored");
        print("Flutter restored normal mode");
        _pipTransitionStart = null;
        updateState(FloatingVideoState.pipExited);
        // Restore to waitingForMinimize if video is still playing
        if (_lastKnownIsPlaying) {
          updateState(FloatingVideoState.waitingForMinimize);
        } else {
          updateState(FloatingVideoState.idle);
        }
      }
    };
  }

  FloatingVideoModel? get activeVideo => _activeVideo;
  FloatingVideoState get state => _state;
  BrowserRenderMode get renderMode => _renderMode;
  
  double get opacity => _opacity;
  double get playbackRate => _playbackRate;
  
  double get width => _width;
  double get height => _height;
  
  double get positionX => _positionX;
  double get positionY => _positionY;

  bool get isPipActive => _renderMode == BrowserRenderMode.pipActive;

  // Expose cached dimensions for PiP view
  int get lastKnownVideoWidth => _lastKnownVideoWidth;
  int get lastKnownVideoHeight => _lastKnownVideoHeight;
  Map<String, dynamic> get lastKnownBoundingRect => _lastKnownBoundingRect;

  bool get _isInPipTransition {
    if (_pipTransitionStart == null) return false;
    return DateTime.now().difference(_pipTransitionStart!) < _pipTransitionWindow;
  }

  bool get isInPipMode => _renderMode == BrowserRenderMode.pipActive || _renderMode == BrowserRenderMode.pipPreparing;

  void setRenderMode(BrowserRenderMode mode) {
    if (_renderMode != mode) {
      _renderMode = mode;
      if (mode == BrowserRenderMode.pipPreparing) {
        print("Preparing PiP: switching to video-only render mode");
      } else if (mode == BrowserRenderMode.pipActive) {
        print("PiP active");
      } else if (mode == BrowserRenderMode.normal) {
        print("PiP exited, normal browser UI restored");
      }
      notifyListeners();
    }
  }

  Future<void> _injectPipCleanupScript() async {
    final controller = _webViewController;
    if (controller != null) {
      try {
        final dynamic result = await controller.evaluateJavascript(source: """
          (function () {
            window.__zyroPipCleanupActive = true;

            const old = document.getElementById('zyro-pip-video-only-style');
            if (old) old.remove();

            const videos = Array.from(document.querySelectorAll('video'));
            const activeVideo =
              videos.find(v => !v.paused && !v.ended && v.videoWidth > 0 && v.videoHeight > 0) ||
              videos.sort((a, b) => (b.currentTime || 0) - (a.currentTime || 0))[0];

            if (!activeVideo) return null;

            document.querySelectorAll('[data-zyro-pip-video]').forEach(el => el.removeAttribute('data-zyro-pip-video'));
            document.querySelectorAll('[data-zyro-pip-ancestor]').forEach(el => el.removeAttribute('data-zyro-pip-ancestor'));

            activeVideo.setAttribute('data-zyro-pip-video', 'true');
            document.documentElement.classList.add('zyro-pip-video-only');

            let parent = activeVideo.parentElement;
            while (parent && parent !== document.body) {
              parent.setAttribute('data-zyro-pip-ancestor', 'true');
              parent = parent.parentElement;
            }

            const style = document.createElement('style');
            style.id = 'zyro-pip-video-only-style';
            style.textContent = `
              html.zyro-pip-video-only,
              html.zyro-pip-video-only body {
                margin: 0 !important;
                padding: 0 !important;
                width: 100vw !important;
                height: 100vh !important;
                overflow: hidden !important;
                background: #000 !important;
              }

              html.zyro-pip-video-only body * {
                display: none !important;
                visibility: hidden !important;
                opacity: 0 !important;
                pointer-events: none !important;
              }

              html.zyro-pip-video-only [data-zyro-pip-ancestor="true"] {
                display: block !important;
                visibility: visible !important;
                opacity: 1 !important;
                position: static !important;
                margin: 0 !important;
                padding: 0 !important;
                width: auto !important;
                height: auto !important;
                overflow: visible !important;
                background: transparent !important;
                border: none !important;
                box-shadow: none !important;
                transform: none !important;
                clip: auto !important;
                clip-path: none !important;
              }

              html.zyro-pip-video-only video[data-zyro-pip-video="true"] {
                display: block !important;
                visibility: visible !important;
                opacity: 1 !important;
                pointer-events: auto !important;
                position: fixed !important;
                top: 0 !important;
                left: 0 !important;
                width: 100vw !important;
                height: 100vh !important;
                object-fit: contain !important;
                background: #000 !important;
                z-index: 2147483647 !important;
              }
            `;
            document.head.appendChild(style);

            function hideNonVideoOverlays() {
              if (!window.__zyroPipCleanupActive) return;

              const videos = Array.from(document.querySelectorAll('video'));
              const activeVideo =
                videos.find(v => !v.paused && !v.ended && v.videoWidth > 0 && v.videoHeight > 0) ||
                videos.sort((a, b) => (b.currentTime || 0) - (a.currentTime || 0))[0];

              if (!activeVideo) return;

              if (activeVideo.getAttribute('data-zyro-pip-video') !== 'true') {
                document.querySelectorAll('[data-zyro-pip-video]').forEach(el => el.removeAttribute('data-zyro-pip-video'));
                activeVideo.setAttribute('data-zyro-pip-video', 'true');
              }

              const currentAncestors = new Set();
              let parent = activeVideo.parentElement;
              while (parent && parent !== document.body) {
                currentAncestors.add(parent);
                parent = parent.parentElement;
              }

              document.querySelectorAll('[data-zyro-pip-ancestor]').forEach(el => {
                if (!currentAncestors.has(el)) {
                  el.removeAttribute('data-zyro-pip-ancestor');
                }
              });

              currentAncestors.forEach(el => {
                if (el.getAttribute('data-zyro-pip-ancestor') !== 'true') {
                  el.setAttribute('data-zyro-pip-ancestor', 'true');
                }
              });

              // Set inline display none on all other elements to override high-specificity !important styles
              document.querySelectorAll('body *').forEach(el => {
                if (el !== activeVideo && !currentAncestors.has(el)) {
                  el.style.setProperty('display', 'none', 'important');
                  el.style.setProperty('visibility', 'hidden', 'important');
                  el.style.setProperty('opacity', '0', 'important');
                }
              });
            }

            window.hideNonVideoOverlays = hideNonVideoOverlays;
            
            // Store playback state BEFORE DOM manipulation
            const wasPlaying = !activeVideo.paused;
            hideNonVideoOverlays();

            // Resume playback after DOM manipulation if video was playing
            if (wasPlaying && activeVideo.paused) {
              try {
                activeVideo.play().catch(e => {
                  console.warn("Failed to resume video after PiP cleanup:", e);
                });
              } catch (e) {
                console.warn("Error resuming video playback:", e);
              }
            }

            // Periodic cleanup with playback preservation
            window.__zyroPipCleanupInterval = setInterval(() => {
              hideNonVideoOverlays();
              // Ensure video stays playing in PiP mode
              const videos = Array.from(document.querySelectorAll('video'));
              const pipVideo = videos.find(v => v.getAttribute('data-zyro-pip-video') === 'true');
              if (pipVideo && pipVideo.paused) {
                try {
                  pipVideo.play().catch(e => {
                    console.warn("Failed to keep video playing in PiP:", e);
                  });
                } catch (e) {
                  console.warn("Error in PiP playback preservation:", e);
                }
              }
            }, 250);

            setTimeout(() => {
              if (window.__zyroPipCleanupInterval) {
                clearInterval(window.__zyroPipCleanupInterval);
                window.__zyroPipCleanupInterval = null;
              }
            }, 3000);

            const rect = activeVideo.getBoundingClientRect();
            return {
              'x': rect.left,
              'y': rect.top,
              'width': rect.width,
              'height': rect.height,
              'videoWidth': activeVideo.videoWidth,
              'videoHeight': activeVideo.videoHeight,
              'isPlaying': !activeVideo.paused,
              'currentTime': activeVideo.currentTime,
              'duration': activeVideo.duration
            };
          })();
        """);

        if (result != null) {
          final data = Map<String, dynamic>.from(result as Map);
          print("Active video detected");
          print("Video rect captured");

          final int vw = data['videoWidth'] ?? 0;
          final int vh = data['videoHeight'] ?? 0;
          if (vw > 0 && vh > 0) {
            print("Video dimensions valid");
            _lastKnownVideoWidth = vw;
            _lastKnownVideoHeight = vh;
          }
          if (data['x'] != null && data['y'] != null && data['width'] != null && data['height'] != null) {
            _lastKnownBoundingRect = {
              'left': data['x'],
              'top': data['y'],
              'width': data['width'],
              'height': data['height'],
            };
          }
        }
      } catch (e) {
        print("Error executing PiP transform script: $e");
      }
    }
  }

  Future<void> enterVideoPip() async {
    print("Preparing native PiP");
    setRenderMode(BrowserRenderMode.pipPreparing);
    print("Browser UI hidden");
    print("Waiting one frame before enterPictureInPictureMode");

    final isSupported = await FloatingVideoChannel.isPictureInPictureSupported();
    print("PiP supported=$isSupported");
    if (!isSupported) {
      print("PiP failed: not supported");
      setRenderMode(BrowserRenderMode.normal);
      return;
    }

    final controller = _webViewController;
    bool customViewReady = false;

    // Check if custom video view is already active
    customViewReady = await FloatingVideoChannel.isCustomVideoViewActive();

    if (!customViewReady && controller != null) {
      print("Requesting native fullscreen via JavaScript");
      await controller.evaluateJavascript(source: """
        (function() {
          const videos = Array.from(document.querySelectorAll('video'));
          const activeVideo = videos.find(v => !v.paused && !v.ended && v.videoWidth > 0 && v.videoHeight > 0) || videos[0];
          if (activeVideo) {
            if (activeVideo.requestFullscreen) {
              activeVideo.requestFullscreen();
            } else if (activeVideo.webkitRequestFullscreen) {
              activeVideo.webkitRequestFullscreen();
            } else if (activeVideo.webkitEnterFullscreen) {
              activeVideo.webkitEnterFullscreen();
            }
            return true;
          }
          return false;
        })();
      """);

      // Wait up to 1.5 seconds for custom video view to become active on Android
      int retries = 0;
      while (retries < 15) {
        customViewReady = await FloatingVideoChannel.isCustomVideoViewActive();
        if (customViewReady) break;
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
    }

    print("Custom video view available=$customViewReady");

    if (customViewReady) {
      print("Using custom video view PiP");
    } else {
      print("Using Activity WebView PiP fallback");
      await _injectPipCleanupScript();
      print("Video-only DOM isolation applied");
      await Future.delayed(const Duration(milliseconds: 300));
    }

    var pipWidth = _activeVideo?.videoWidth ?? 0;
    var pipHeight = _activeVideo?.videoHeight ?? 0;
    if (pipWidth <= 0 || pipHeight <= 0) {
      pipWidth = _lastKnownVideoWidth;
      pipHeight = _lastKnownVideoHeight;
      print("Using cached video dimensions ${pipWidth}x${pipHeight}");
    }
    if (pipWidth <= 0 || pipHeight <= 0) {
      print("Invalid video dimensions ignored");
      pipWidth = 1920;
      pipHeight = 1080;
      print("Cached video dimensions used");
    }

    print("PiP aspect ratio applied");

    final double vx = (_lastKnownBoundingRect['left'] ?? 0.0).toDouble();
    final double vy = (_lastKnownBoundingRect['top'] ?? 0.0).toDouble();
    final double vw = (_lastKnownBoundingRect['width'] ?? 0.0).toDouble();
    final double vh = (_lastKnownBoundingRect['height'] ?? 0.0).toDouble();

    // Sync dimensions to native before PiP
    await FloatingVideoChannel.setVideoPlaying(
      true,
      videoWidth: pipWidth,
      videoHeight: pipHeight,
      videoTitle: _activeVideo?.videoTitle ?? "",
      pageUrl: _activeVideo?.pageUrl ?? "",
      duration: _activeVideo?.duration ?? 0.0,
      currentTime: _activeVideo?.currentTime ?? 0.0,
      isVisible: true,
      videoX: vx,
      videoY: vy,
      videoRectWidth: vw,
      videoRectHeight: vh,
    );

    print("PiP requested");
    final success = await FloatingVideoChannel.enterPictureInPicture();
    if (success) {
      print("PiP entered");
    } else {
      print("PiP failed: enterPictureInPictureMode returned false");
    }
  }

  void updateState(FloatingVideoState newState) {
    if (_state != newState) {
      _state = newState;
      print("[FLOATING VIDEO STATE] State changed to $_state");
      notifyListeners();
    }
  }

  void updateActiveVideo(FloatingVideoModel video, InAppWebViewController? controller) {
    // During PiP transition, ignore stale reports with 0x0 dimensions or isPlaying=false
    if (isInPipMode || _isInPipTransition) {
      if (video.videoWidth <= 0 || video.videoHeight <= 0 || !video.isPlaying) {
        if (video.videoWidth <= 0 || video.videoHeight <= 0) {
          print("Ignoring invalid 0x0 during PiP transition");
        }
        print("[FLOATING VIDEO DEBUG] Ignoring stale video update during PiP transition: "
            "dimensions=${video.videoWidth}x${video.videoHeight}, isPlaying=${video.isPlaying}");
        // Only update currentTime if it's valid (timeline continues in PiP)
        if (video.currentTime > 0 && video.isPlaying) {
          _lastKnownCurrentTime = video.currentTime;
        }
        return;
      }
    }

    _activeVideo = video;
    _webViewController = controller;
    _playbackRate = video.playbackRate;
    
    print("Active video detected");
    print("[FLOATING VIDEO DEBUG] video detected: Title=${video.videoTitle}, "
        "isPlaying=${video.isPlaying}, isVisible=${video.isVisible}, "
        "dimensions=${video.videoWidth}x${video.videoHeight}");

    // Cache valid video dimensions
    if (video.videoWidth > 0 && video.videoHeight > 0) {
      _lastKnownVideoWidth = video.videoWidth;
      _lastKnownVideoHeight = video.videoHeight;
      print("[FLOATING VIDEO DEBUG] Cached video dimensions: ${_lastKnownVideoWidth}x${_lastKnownVideoHeight}");
      print("Video dimensions cached");
    }
    if (video.boundingRect.isNotEmpty) {
      final w = (video.boundingRect['width'] ?? 0.0).toDouble();
      final h = (video.boundingRect['height'] ?? 0.0).toDouble();
      if (w > 0 && h > 0) {
        _lastKnownBoundingRect = Map<String, dynamic>.from(video.boundingRect);
      }
    }
    _lastKnownVideoTitle = video.videoTitle;
    _lastKnownCurrentTime = video.currentTime;
    _lastKnownDuration = video.duration;
    _lastKnownVideoUrl = video.pageUrl;
    _lastKnownIsPlaying = video.isPlaying;
    _lastKnownIsVisible = video.isVisible;

    // State machine updates - only when NOT in PiP mode
    if (!isInPipMode) {
      if (video.isPlaying) {
        updateState(FloatingVideoState.waitingForMinimize);
        print("[FLOATING VIDEO DEBUG] foreground browsing mode no overlay shown. placeholder overlay blocked.");
      } else {
        updateState(FloatingVideoState.videoDetected);
      }
    }
    
    // Sync with native PiP state - use cached dimensions if current are invalid
    final bool useCached = video.videoWidth <= 0 || video.videoHeight <= 0;
    if (useCached) {
      print("Using cached video dimensions ${_lastKnownVideoWidth}x${_lastKnownVideoHeight}");
    }
    final syncWidth = video.videoWidth > 0 ? video.videoWidth : _lastKnownVideoWidth;
    final syncHeight = video.videoHeight > 0 ? video.videoHeight : _lastKnownVideoHeight;
    
    final double vx = (video.boundingRect['left'] ?? _lastKnownBoundingRect['left'] ?? 0.0).toDouble();
    final double vy = (video.boundingRect['top'] ?? _lastKnownBoundingRect['top'] ?? 0.0).toDouble();
    final double vw = (video.boundingRect['width'] ?? _lastKnownBoundingRect['width'] ?? 0.0).toDouble();
    final double vh = (video.boundingRect['height'] ?? _lastKnownBoundingRect['height'] ?? 0.0).toDouble();

    FloatingVideoChannel.setVideoPlaying(
      video.isPlaying,
      videoWidth: syncWidth > 0 ? syncWidth : 1920,
      videoHeight: syncHeight > 0 ? syncHeight : 1080,
      videoTitle: video.videoTitle,
      pageUrl: video.pageUrl,
      duration: video.duration,
      currentTime: video.currentTime,
      isVisible: video.isVisible,
      videoX: vx,
      videoY: vy,
      videoRectWidth: vw,
      videoRectHeight: vh,
    );

    notifyListeners();
  }

  void setWebViewController(InAppWebViewController? controller) {
    _webViewController = controller;
  }

  void closeFloatingOverlay() {
    // Don't clear if we're in PiP mode - navigation away should be the only trigger
    if (isInPipMode) {
      print("[FLOATING VIDEO DEBUG] closeFloatingOverlay blocked during PiP mode");
      return;
    }
    _activeVideo = null;
    _lastKnownIsPlaying = false;
    updateState(FloatingVideoState.idle);
    FloatingVideoChannel.setVideoPlaying(false);
    notifyListeners();
  }

  /// Force close - used when tab is actually closed or page navigates away
  void forceClose() {
    _activeVideo = null;
    _lastKnownIsPlaying = false;
    _pipTransitionStart = null;
    updateState(FloatingVideoState.idle);
    FloatingVideoChannel.setVideoPlaying(false);
    notifyListeners();
  }

  Future<void> togglePlay() async {
    final video = _activeVideo;
    final controller = _webViewController;
    if (video == null || controller == null) return;

    final action = video.isPlaying ? 'pause' : 'play';
    final selector = video.videoElementSelector;

    try {
      await controller.evaluateJavascript(
        source: "window.zyroFloatingController.$action('$selector');"
      );
      // Local sync first to make UI snappy
      _activeVideo = video.copyWith(isPlaying: !video.isPlaying);
      _lastKnownIsPlaying = _activeVideo!.isPlaying;
      FloatingVideoChannel.setVideoPlaying(
        _activeVideo!.isPlaying,
        videoWidth: _activeVideo!.videoWidth > 0 ? _activeVideo!.videoWidth : _lastKnownVideoWidth,
        videoHeight: _activeVideo!.videoHeight > 0 ? _activeVideo!.videoHeight : _lastKnownVideoHeight,
        videoTitle: _activeVideo!.videoTitle,
        pageUrl: _activeVideo!.pageUrl,
        duration: _activeVideo!.duration,
        currentTime: _activeVideo!.currentTime,
        isVisible: _activeVideo!.isVisible,
      );
      if (_activeVideo!.isPlaying) {
        updateState(FloatingVideoState.waitingForMinimize);
      } else {
        updateState(FloatingVideoState.videoDetected);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling play in WebView: $e");
    }
  }

  Future<void> setPlaybackSpeed(double rate) async {
    final video = _activeVideo;
    final controller = _webViewController;
    if (video == null || controller == null) return;

    final selector = video.videoElementSelector;
    try {
      await controller.evaluateJavascript(
        source: "window.zyroFloatingController.setSpeed('$selector', $rate);"
      );
      _playbackRate = rate;
      _activeVideo = video.copyWith(playbackRate: rate);
      notifyListeners();
    } catch (e) {
      debugPrint("Error setting playback speed in WebView: $e");
    }
  }

  Future<void> seekTo(double seconds) async {
    final video = _activeVideo;
    final controller = _webViewController;
    if (video == null || controller == null) return;

    final selector = video.videoElementSelector;
    try {
      await controller.evaluateJavascript(
        source: "window.zyroFloatingController.seek('$selector', $seconds);"
      );
      _activeVideo = video.copyWith(currentTime: seconds);
      _lastKnownCurrentTime = seconds;
      notifyListeners();
    } catch (e) {
      debugPrint("Error seeking in WebView: $e");
    }
  }

  void setOpacity(double value) {
    _opacity = value.clamp(0.1, 1.0);
    notifyListeners();
  }

  void updatePosition(double x, double y) {
    _positionX = x;
    _positionY = y;
    notifyListeners();
  }

  void updateSize(double w, double h) {
    _width = w.clamp(160.0, 360.0);
    _height = h.clamp(90.0, 203.0);
    notifyListeners();
  }
}
