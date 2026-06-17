class DownloadedVideo {
  final String id;
  final String title;
  final String videoId;
  final String sourceUrl;
  final String localFilePath;
  final String quality;
  final int fileSize; // in bytes
  final int duration; // in seconds
  final String thumbnailPath;
  final DateTime downloadedAt;
  final String mimeType;

  DownloadedVideo({
    required this.id,
    required this.title,
    required this.videoId,
    required this.sourceUrl,
    required this.localFilePath,
    required this.quality,
    required this.fileSize,
    required this.duration,
    required this.thumbnailPath,
    required this.downloadedAt,
    required this.mimeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoId': videoId,
      'sourceUrl': sourceUrl,
      'localFilePath': localFilePath,
      'quality': quality,
      'fileSize': fileSize,
      'duration': duration,
      'thumbnailPath': thumbnailPath,
      'downloadedAt': downloadedAt.toIso8601String(),
      'mimeType': mimeType,
    };
  }

  factory DownloadedVideo.fromJson(Map<String, dynamic> json) {
    return DownloadedVideo(
      id: json['id'] as String,
      title: json['title'] as String,
      videoId: json['videoId'] as String,
      sourceUrl: json['sourceUrl'] as String,
      localFilePath: json['localFilePath'] as String,
      quality: json['quality'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      thumbnailPath: json['thumbnailPath'] as String,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
      mimeType: json['mimeType'] as String,
    );
  }
}
