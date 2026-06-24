import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as path;
import '../../video_downloader/services/media_store_service.dart';
import '../models/screenshot_capture_result.dart';

class ScreenshotCaptureService {
  final MediaStoreService _storage = MediaStoreService();

  Future<ScreenshotCaptureResult> captureVisible({
    required InAppWebViewController controller,
    required String title,
    required String url,
  }) async {
    if (kDebugMode) debugPrint('[SCREENSHOT PRO] Visible screenshot started');
    final bytes = await controller.takeScreenshot();
    if (bytes == null || bytes.isEmpty)
      throw StateError('WebView capture returned no image');
    final result = await savePng(
      bytes,
      title: title,
      url: url,
      prefix: 'zyro_screenshot',
    );
    if (kDebugMode)
      debugPrint(
        '[SCREENSHOT PRO] Visible screenshot saved: ${result.filePath}',
      );
    return result;
  }

  Future<ScreenshotCaptureResult> savePng(
    Uint8List bytes, {
    required String title,
    required String url,
    required String prefix,
    String type = 'visible',
  }) async {
    final directory = await _storage.getSaveDirectoryPath(
      subFolder: 'screenshots',
    );
    final now = DateTime.now();
    final host = Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'page';
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final fileName = _storage.sanitizeFileName('${prefix}_${host}_$stamp.png');
    final file = File(path.join(directory, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return ScreenshotCaptureResult(
      filePath: file.path,
      fileName: fileName,
      mimeType: 'image/png',
      captureType: type,
      title: title,
      url: url,
      createdAt: now,
      fileSize: await file.length(),
    );
  }
}
