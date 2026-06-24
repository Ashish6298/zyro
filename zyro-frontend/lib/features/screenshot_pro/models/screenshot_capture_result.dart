class ScreenshotCaptureResult {
  final String filePath;
  final String fileName;
  final String mimeType;
  final String captureType;
  final String title;
  final String url;
  final DateTime createdAt;
  final int fileSize;

  const ScreenshotCaptureResult({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.captureType,
    required this.title,
    required this.url,
    required this.createdAt,
    required this.fileSize,
  });
}
