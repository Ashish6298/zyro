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
      final first = await controller.takeScreenshot();
      if (first == null) throw StateError('Unable to capture page');
      final firstImage = img.decodePng(first);
      if (firstImage == null) throw StateError('Unable to decode page image');
      final scale = firstImage.height / viewport;
      final maxCssHeight = (_maxOutputHeight / scale).floor().toDouble();
      final captureHeight = documentHeight.clamp(viewport, maxCssHeight);
      final maxOffset = (captureHeight - viewport).clamp(0, double.infinity);
      final segmentCount = (maxOffset / viewport).ceil() + 1;

      for (var index = 0; index < segmentCount; index++) {
        final offset = (index * viewport).clamp(0, maxOffset).toDouble();
        await controller.scrollTo(x: 0, y: offset.toInt());
        await Future<void>.delayed(const Duration(milliseconds: 280));
        final bytes = await controller.takeScreenshot();
        if (bytes == null) throw StateError('Unable to capture page segment');
        final image = img.decodePng(bytes);
        if (image == null) throw StateError('Unable to decode page segment');
        images.add(image);
        offsets.add(offset);
        onProgress?.call((index + 1) / segmentCount);
        if (kDebugMode)
          debugPrint(
            '[SCREENSHOT PRO] Segment captured ${index + 1}/$segmentCount',
          );
      }

      final outputHeight = (captureHeight * scale).ceil().clamp(
        1,
        _maxOutputHeight,
      );
      final output = img.Image(width: images.first.width, height: outputHeight);
      for (var index = 0; index < images.length; index++) {
        final start = (offsets[index] * scale).round();
        final end = index == images.length - 1
            ? outputHeight
            : (offsets[index + 1] * scale).round();
        final height = (end - start).clamp(1, images[index].height);
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
      return _screenshotService.savePng(
        Uint8List.fromList(img.encodePng(output)),
        title: title,
        url: url,
        prefix: 'zyro_fullpage',
        type: 'full_page',
      );
    } finally {
      await controller.scrollTo(x: 0, y: originalY.toInt());
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
}
