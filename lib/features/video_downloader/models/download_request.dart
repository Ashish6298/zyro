enum DownloadState {
  extracting,
  downloadingVideo,
  downloadingAudio,
  merging,
  completed,
  failed,
  idle
}

class DownloadRequest {
  final String id;
  final String url;
  final String title;
  final String formatId;
  final int? expectedHeight;
  final String mode;
  final DownloadState state;
  final double progress;
  final String? error;
  final String? downloadUrl;
  final String? filename;

  DownloadRequest({
    required this.id,
    required this.url,
    required this.title,
    required this.formatId,
    this.expectedHeight,
    required this.mode,
    required this.state,
    required this.progress,
    this.error,
    this.downloadUrl,
    this.filename,
  });

  DownloadRequest copyWith({
    DownloadState? state,
    double? progress,
    String? error,
    String? downloadUrl,
    String? filename,
  }) {
    return DownloadRequest(
      id: id,
      url: url,
      title: title,
      formatId: formatId,
      expectedHeight: expectedHeight,
      mode: mode,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      filename: filename ?? this.filename,
    );
  }
}
