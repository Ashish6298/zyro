class FloatingVideoModel {
  final String tabId;
  final String pageUrl;
  final String videoTitle;
  final double currentTime;
  final double duration;
  final bool isPlaying;
  final String videoElementSelector;
  final String thumbnail;
  final String sourceDomain;
  final double playbackRate;
  
  // Extra PiP fields
  final bool isPaused;
  final bool ended;
  final int videoWidth;
  final int videoHeight;
  final Map<String, dynamic> boundingRect;
  final bool isVisible;
  final bool isAd;

  FloatingVideoModel({
    required this.tabId,
    required this.pageUrl,
    required this.videoTitle,
    required this.currentTime,
    required this.duration,
    required this.isPlaying,
    required this.videoElementSelector,
    required this.thumbnail,
    required this.sourceDomain,
    this.playbackRate = 1.0,
    required this.isPaused,
    required this.ended,
    required this.videoWidth,
    required this.videoHeight,
    required this.boundingRect,
    required this.isVisible,
    required this.isAd,
  });

  FloatingVideoModel copyWith({
    String? tabId,
    String? pageUrl,
    String? videoTitle,
    double? currentTime,
    double? duration,
    bool? isPlaying,
    String? videoElementSelector,
    String? thumbnail,
    String? sourceDomain,
    double? playbackRate,
    bool? isPaused,
    bool? ended,
    int? videoWidth,
    int? videoHeight,
    Map<String, dynamic>? boundingRect,
    bool? isVisible,
    bool? isAd,
  }) {
    return FloatingVideoModel(
      tabId: tabId ?? this.tabId,
      pageUrl: pageUrl ?? this.pageUrl,
      videoTitle: videoTitle ?? this.videoTitle,
      currentTime: currentTime ?? this.currentTime,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      videoElementSelector: videoElementSelector ?? this.videoElementSelector,
      thumbnail: thumbnail ?? this.thumbnail,
      sourceDomain: sourceDomain ?? this.sourceDomain,
      playbackRate: playbackRate ?? this.playbackRate,
      isPaused: isPaused ?? this.isPaused,
      ended: ended ?? this.ended,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      boundingRect: boundingRect ?? this.boundingRect,
      isVisible: isVisible ?? this.isVisible,
      isAd: isAd ?? this.isAd,
    );
  }

  factory FloatingVideoModel.fromMap(Map<String, dynamic> map, String tabId) {
    return FloatingVideoModel(
      tabId: tabId,
      pageUrl: map['pageUrl'] ?? '',
      videoTitle: map['videoTitle'] ?? 'Untitled Video',
      currentTime: (map['currentTime'] ?? 0.0).toDouble(),
      duration: (map['duration'] ?? 0.0).toDouble(),
      isPlaying: map['isPlaying'] == true,
      videoElementSelector: map['videoElementSelector'] ?? 'video',
      thumbnail: map['thumbnail'] ?? '',
      sourceDomain: map['sourceDomain'] ?? '',
      playbackRate: (map['playbackRate'] ?? 1.0).toDouble(),
      isPaused: map['isPaused'] == true,
      ended: map['ended'] == true,
      videoWidth: (map['videoWidth'] ?? 0).toInt(),
      videoHeight: (map['videoHeight'] ?? 0).toInt(),
      boundingRect: Map<String, dynamic>.from(map['boundingRect'] ?? {}),
      isVisible: map['isVisible'] == true,
      isAd: map['isAd'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tabId': tabId,
      'pageUrl': pageUrl,
      'videoTitle': videoTitle,
      'currentTime': currentTime,
      'duration': duration,
      'isPlaying': isPlaying,
      'videoElementSelector': videoElementSelector,
      'thumbnail': thumbnail,
      'sourceDomain': sourceDomain,
      'playbackRate': playbackRate,
      'isPaused': isPaused,
      'ended': ended,
      'videoWidth': videoWidth,
      'videoHeight': videoHeight,
      'boundingRect': boundingRect,
      'isVisible': isVisible,
      'isAd': isAd,
    };
  }
}
