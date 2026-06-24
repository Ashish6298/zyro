import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../../video_downloader/services/media_store_service.dart';

class ScreenshotPdfExportService {
  Future<File> savePaginated(Uint8List png, String url) async {
    final image = pw.MemoryImage(png);
    final decoded = img.decodePng(png);
    if (decoded == null) throw StateError('Unable to decode screenshot');
    final page = PdfPageFormat.a4;
    const margin = 16.0;
    final printableWidth = page.width - margin * 2;
    final printableHeight = page.height - margin * 2;
    final scale = printableWidth / decoded.width;
    final sliceHeight = printableHeight / scale;
    if (kDebugMode) {
      debugPrint('[SCREENSHOT PRO] PDF export started');
      debugPrint('[SCREENSHOT PRO] Long image ${decoded.width}x${decoded.height}');
      debugPrint('[SCREENSHOT PRO] A4 printable area ${printableWidth}x$printableHeight; scale=$scale; slice=$sliceHeight');
    }
    final pdf = pw.Document();
    var pages = 0;
    for (var offset = 0.0; offset < decoded.height; offset += sliceHeight) {
      final height = min(sliceHeight, decoded.height - offset).round();
      final slice = img.copyCrop(decoded, x: 0, y: offset.round(), width: decoded.width, height: height);
      final sliceImage = pw.MemoryImage(Uint8List.fromList(img.encodePng(slice)));
      pdf.addPage(pw.Page(pageFormat: page, margin: const pw.EdgeInsets.all(margin), build: (_) => pw.Center(child: pw.Image(sliceImage, width: printableWidth, fit: pw.BoxFit.fitWidth))));
      pages++;
      if (kDebugMode) debugPrint('[SCREENSHOT PRO] PDF page slice added: $pages');
    }
    final dir = await MediaStoreService().getSaveDirectoryPath(subFolder: 'screenshots');
    final host = Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? 'page';
    final file = File('$dir/zyro_fullpage_${host}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save(), flush: true);
    if (kDebugMode) debugPrint('[SCREENSHOT PRO] PDF saved successfully: $pages pages');
    return file;
  }
}
