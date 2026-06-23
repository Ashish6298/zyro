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
    FloatingVideoChannel.onPipModeChangedCallback = (active) {
      if (active) {
        setRenderMode(BrowserRenderMode.pipActive);
        _pipTransitionStart = DateTime.now();
        updateState(FloatingVideoState.pipActive);
      } else {
        setRenderMode(BrowserRenderMode.normal);
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

  Future<void> enterVideoPip() async {
    setRenderMode(BrowserRenderMode.pipPreparing);
    print("Waiting one frame before enterPictureInPictureMode");
    await Future.delayed(const Duration(milliseconds: 120));
    print("Native PiP requested after video-only view rendered");

    var pipWidth = _activeVideo?.videoWidth ?? 0;
    var pipHeight = _activeVideo?.videoHeight ?? 0;
    if (pipWidth <= 0 || pipHeight <= 0) {
      pipWidth = _lastKnownVideoWidth;
      pipHeight = _lastKnownVideoHeight;
      print("Using cached video dimensions ${pipWidth}x${pipHeight}");
    }
    if (pipWidth <= 0 || pipHeight <= 0) {
      pipWidth = 1920;
      pipHeight = 1080;
    }

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
    );

    await FloatingVideoChannel.enterPictureInPicture();
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
    
    print("[FLOATING VIDEO DEBUG] video detected: Title=${video.videoTitle}, "
        "isPlaying=${video.isPlaying}, isVisible=${video.isVisible}, "
        "dimensions=${video.videoWidth}x${video.videoHeight}");

    // Cache valid video dimensions
    if (video.videoWidth > 0 && video.videoHeight > 0) {
      _lastKnownVideoWidth = video.videoWidth;
      _lastKnownVideoHeight = video.videoHeight;
      print("[FLOATING VIDEO DEBUG] Cached video dimensions: ${_lastKnownVideoWidth}x${_lastKnownVideoHeight}");
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
    
    FloatingVideoChannel.setVideoPlaying(
      video.isPlaying,
      videoWidth: syncWidth > 0 ? syncWidth : 1920,
      videoHeight: syncHeight > 0 ? syncHeight : 1080,
      videoTitle: video.videoTitle,
      pageUrl: video.pageUrl,
      duration: video.duration,
      currentTime: video.currentTime,
      isVisible: video.isVisible,
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
