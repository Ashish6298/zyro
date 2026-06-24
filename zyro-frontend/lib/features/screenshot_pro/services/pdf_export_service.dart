import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/screenshot_capture_result.dart';

class PdfExportService {
  static const _channel = MethodChannel('zyro/screenshot_pro');

  Future<ScreenshotCaptureResult> export({
    required String title,
    required String url,
  }) async {
    if (kDebugMode) debugPrint('[SCREENSHOT PRO] PDF export started');
    final value = await _channel.invokeMapMethod<String, dynamic>(
      'exportWebViewPdf',
      {'title': title, 'url': url},
    );
    final filePath = value?['filePath'];
    if (filePath is! String || filePath.isEmpty)
      throw StateError('PDF export failed');
    final file = File(filePath);
    final result = ScreenshotCaptureResult(
      filePath: filePath,
      fileName: value?['fileName'] as String? ?? file.uri.pathSegments.last,
      mimeType: 'application/pdf',
      captureType: 'pdf',
      title: title,
      url: url,
      createdAt: DateTime.now(),
      fileSize: await file.length(),
    );
    if (kDebugMode)
      debugPrint('[SCREENSHOT PRO] PDF saved: ${result.filePath}');
    return result;
  }
}
