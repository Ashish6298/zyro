import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/models/tab_model.dart';
import '../../website_vault/controllers/website_vault_controller.dart';
import '../models/screenshot_capture_result.dart';
import '../services/full_page_capture_service.dart';
import '../services/pdf_export_service.dart';
import '../services/screenshot_capture_service.dart';
import '../widgets/capture_progress_dialog.dart';
import '../widgets/screenshot_option_tile.dart';

class ScreenshotProSheet extends StatelessWidget {
  final TabModel tab;
  const ScreenshotProSheet({super.key, required this.tab});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'SCREENSHOT PRO',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.3,
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'CAPTURE CURRENT PAGE',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Files are saved in Zyro/Screenshots.',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.58),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        ScreenshotOptionTile(
          icon: LucideIcons.camera,
          title: 'Visible Screenshot',
          description: 'Capture the currently visible website page',
          onTap: () => _captureVisible(context),
        ),
        ScreenshotOptionTile(
          icon: LucideIcons.scroll,
          title: 'Full Page Screenshot',
          description: 'Capture the complete page from top to bottom',
          onTap: () => _captureFullPage(context),
        ),
        ScreenshotOptionTile(
          icon: LucideIcons.fileText,
          title: 'Export Page as PDF',
          description: 'Save the current webpage as a PDF document',
          onTap: () => _exportPdf(context),
        ),
      ],
    ),
  );

  Future<bool> _ready(BuildContext context) async {
    if (tab.controller == null) {
      _error(context, 'The page is not ready yet.');
      return false;
    }
    if (!tab.isIncognito) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Save incognito capture?'),
            content: const Text(
              'This capture will be saved to device storage.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _captureVisible(BuildContext context) async {
    if (!await _ready(context) || !context.mounted) return;
    if (kDebugMode) debugPrint('[SCREENSHOT PRO] opened visible capture');
    await _run(
      context,
      'Capturing visible page…',
      () => ScreenshotCaptureService().captureVisible(
        controller: tab.controller!,
        title: tab.title ?? 'Website page',
        url: tab.url,
      ),
    );
  }

  Future<void> _captureFullPage(BuildContext context) async {
    if (!await _ready(context) || !context.mounted) return;
    final progress = ValueNotifier<double>(0);
    await _run(
      context,
      'Capturing full page…',
      () => FullPageCaptureService().capture(
        controller: tab.controller!,
        title: tab.title ?? 'Website page',
        url: tab.url,
        onProgress: (value) => progress.value = value,
      ),
      progress: progress,
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (!await _ready(context) || !context.mounted) return;
    await _run(
      context,
      'Exporting PDF…',
      () => PdfExportService().export(
        title: tab.title ?? 'Website page',
        url: tab.url,
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    String message,
    Future<ScreenshotCaptureResult> Function() action, {
    ValueNotifier<double>? progress,
  }) async {
    final notifier = progress ?? ValueNotifier<double>(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          CaptureProgressDialog(progress: notifier, message: message),
    );
    try {
      final result = await action();
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        await context.read<WebsiteVaultController>().linkScreenshot(
          title: result.title,
          sourceUrl: result.url,
          filePath: result.filePath,
          mimeType: result.mimeType,
          fileSize: result.fileSize,
          captureType: result.captureType,
        );
      }
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.captureType == 'pdf'
                  ? 'PDF exported successfully'
                  : 'Screenshot saved successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (kDebugMode) debugPrint('[SCREENSHOT PRO] Capture failed: $error');
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) _error(context, 'Capture failed: $error');
    } finally {
      notifier.dispose();
    }
  }

  void _error(BuildContext context, String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
}
