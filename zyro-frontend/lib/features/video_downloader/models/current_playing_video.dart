class CurrentPlayingVideo {
  final String sourcePageUrl;
  final String canonicalVideoUrl;
  final String videoId;
  final String title;
  final String thumbnail;
  final int duration; // in seconds
  final int currentPlaybackTime; // in seconds
  final DateTime detectedAt;
  final bool isPlaying;

  CurrentPlayingVideo({
    required this.sourcePageUrl,
    required this.canonicalVideoUrl,
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.currentPlaybackTime,
    required this.detectedAt,
    required this.isPlaying,
  });

  CurrentPlayingVideo copyWith({
    String? sourcePageUrl,
    String? canonicalVideoUrl,
    String? videoId,
    String? title,
    String? thumbnail,
    int? duration,
    int? currentPlaybackTime,
    DateTime? detectedAt,
    bool? isPlaying,
  }) {
    return CurrentPlayingVideo(
      sourcePageUrl: sourcePageUrl ?? this.sourcePageUrl,
      canonicalVideoUrl: canonicalVideoUrl ?? this.canonicalVideoUrl,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      currentPlaybackTime: currentPlaybackTime ?? this.currentPlaybackTime,
      detectedAt: detectedAt ?? this.detectedAt,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourcePageUrl': sourcePageUrl,
      'canonicalVideoUrl': canonicalVideoUrl,
      'videoId': videoId,
      'title': title,
      'thumbnail': thumbnail,
      'duration': duration,
      'currentPlaybackTime': currentPlaybackTime,
      'detectedAt': detectedAt.toIso8601String(),
      'isPlaying': isPlaying,
    };
  }

  factory CurrentPlayingVideo.fromJson(Map<String, dynamic> json) {
    return CurrentPlayingVideo(
      sourcePageUrl: json['sourcePageUrl'] as String,
      canonicalVideoUrl: json['canonicalVideoUrl'] as String,
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String,
      duration: (json['duration'] as num).toInt(),
      currentPlaybackTime: (json['currentPlaybackTime'] as num).toInt(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      isPlaying: json['isPlaying'] as bool,
    );
  }
}
