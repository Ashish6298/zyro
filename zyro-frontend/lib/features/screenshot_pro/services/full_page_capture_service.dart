import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image/image.dart' as img;
import '../models/screenshot_capture_result.dart';
import 'screenshot_capture_service.dart';

class FullPageCaptureService {
  static const _maxOutputHeight = 16000;
  final ScreenshotCaptureService _screenshotService =
      ScreenshotCaptureService();

  Future<ScreenshotCaptureResult> capture({
    required InAppWebViewController controller,
    required String title,
    required String url,
    ValueChanged<double>? onProgress,
  }) async {
    if (kDebugMode) debugPrint('[SCREENSHOT PRO] Full page capture started');
    final metrics = await _pageMetrics(controller);
    final originalY = metrics.$1;
    final viewport = metrics.$2;
    final documentHeight = metrics.$3;
    if (viewport <= 0 || documentHeight <= 0)
      throw StateError('Page is not ready to capture');

    final images = <img.Image>[];
    final offsets = <double>[];
    try {
      if (kDebugMode) debugPrint('[SCREENSHOT PRO] Original scroll position saved: $originalY');
      await _style(controller, true);
      final first = await controller.takeScreenshot();
      if (first == null) throw StateError('Unable to capture page');
      final firstImage = img.decodePng(first);
      if (firstImage == null) throw StateError('Unable to decode page image');
      final scale = firstImage.height / viewport;
      final maxCssHeight = (_maxOutputHeight / scale).floor().toDouble();
      final captureHeight = documentHeight.clamp(viewport, maxCssHeight).toDouble();
      final maxOffset = (captureHeight - viewport).clamp(0, double.infinity).toDouble();
      final positions = <double>{};
      for (var value = 0.0; value < maxOffset; value += viewport) { positions.add(value); }
      positions.add(maxOffset);
      final ordered = positions.toList()..sort();

      for (var index = 0; index < ordered.length; index++) {
        final offset = await _scroll(controller, ordered[index]);
        if (offsets.isNotEmpty && (offset - offsets.last).abs() < 1) continue;
        await Future<void>.delayed(const Duration(milliseconds: 420));
        final bytes = await controller.takeScreenshot();
        if (bytes == null) throw StateError('Unable to capture page segment');
        final image = img.decodePng(bytes);
        if (image == null) throw StateError('Unable to decode page segment');
        images.add(image);
        offsets.add(offset);
        onProgress?.call((index + 1) / ordered.length);
        if (kDebugMode)
          debugPrint(
            '[SCREENSHOT PRO] Segment captured with actual scrollY: $offset',
          );
      }

      final outputHeight = (captureHeight * scale).ceil().clamp(1, _maxOutputHeight).toInt();
      final output = img.Image(width: images.first.width, height: outputHeight);
      for (var index = 0; index < images.length; index++) {
        final start = (offsets[index] * scale).round();
        final end = index == images.length - 1
            ? outputHeight
            : (offsets[index + 1] * scale).round();
        final height = (end - start).clamp(1, images[index].height).toInt();
        final portion = img.copyCrop(
          images[index],
          x: 0,
          y: 0,
          width: images[index].width,
          height: height,
        );
        img.compositeImage(output, portion, dstX: 0, dstY: start);
      }
      if (kDebugMode) debugPrint('[SCREENSHOT PRO] Image stitching completed');
      return ScreenshotCaptureResult(bytes: img.encodePng(output), filePath: '', fileName: '', mimeType: 'image/png', captureType: 'full_page', title: title, url: url, createdAt: DateTime.now(), fileSize: 0);
    } finally {
      await _style(controller, false);
      await _scroll(controller, originalY);
      if (kDebugMode) debugPrint('[SCREENSHOT PRO] Original scroll restored');
    }
  }

  Future<(double, double, double)> _pageMetrics(
    InAppWebViewController controller,
  ) async {
    final value = await controller.evaluateJavascript(
      source: '''
      ({x: window.scrollX || 0, y: window.scrollY || 0, viewport: window.innerHeight || 0,
        height: Math.max(document.body.scrollHeight, document.documentElement.scrollHeight, document.body.offsetHeight, document.documentElement.offsetHeight) || 0})
    ''',
    );
    final map = Map<String, dynamic>.from(value as Map);
    return (
      (map['y'] as num).toDouble(),
      (map['viewport'] as num).toDouble(),
      (map['height'] as num).toDouble(),
    );
  }

  Future<double> _scroll(InAppWebViewController controller, double y) async {
    final result = await controller.evaluateJavascript(source: 'window.scrollTo(0, ${y.toStringAsFixed(2)}); window.scrollY || 0;');
    return (result as num).toDouble();
  }

  Future<void> _style(InAppWebViewController controller, bool active) async {
    await controller.evaluateJavascript(source: active
        ? "var s=document.createElement('style');s.id='zyro-capture-style';s.textContent='*{scroll-behavior:auto!important}';document.head.appendChild(s);"
        : "document.getElementById('zyro-capture-style')?.remove();");
  }
}
