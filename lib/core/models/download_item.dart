class DownloadItem {
  final String id;
  final String url;
  final String title;
  final String resolution;
  String? filePath;
  int? platformDownloadId;
  double progress;
  bool isCompleted;
  bool isFailed;
  int? totalBytes;
  int downloadedBytes;
  String? errorMessage;
  final DateTime timestamp;

  DownloadItem({
    required this.id,
    required this.url,
    required this.title,
    this.resolution = '720p',
    this.platformDownloadId,
    this.progress = 0,
    this.isCompleted = false,
    this.isFailed = false,
    this.totalBytes,
    this.downloadedBytes = 0,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
