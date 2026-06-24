import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/screenshot_pro_controller.dart';
import '../../../core/models/tab_model.dart';
import '../services/screenshot_capture_service.dart';
import '../services/full_page_capture_service.dart';
import '../services/pdf_export_service.dart';
import '../services/screenshot_pdf_export_service.dart';

class ScreenshotFloatingButton extends StatelessWidget {
  final ScreenshotProController controller;
  final TabModel tab;
  const ScreenshotFloatingButton({super.key, required this.controller, required this.tab});
  @override
  Widget build(BuildContext context) => Positioned(
    right: 22,
    bottom: 126,
    child: ScreenshotFloatingActionMenu(controller: controller, tab: tab),
  );
}

class ScreenshotFloatingActionMenu extends StatelessWidget {
  final ScreenshotProController controller;
  final TabModel tab;
  const ScreenshotFloatingActionMenu({super.key, required this.controller, required this.tab});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ScreenshotMiniActionButton(
        visible: controller.expanded,
        icon: LucideIcons.scroll,
        tooltip: 'Full page screenshot',
        onTap: () async {
          controller.collapse();
          if (kDebugMode)
            debugPrint('[SCREENSHOT PRO] Full page screenshot icon tapped');
          try { final capture = await FullPageCaptureService().capture(controller: tab.controller!, title: tab.title ?? 'Website page', url: tab.url); if (!context.mounted) return; final choice = await _showSaveDialog(context); if (choice == 'image') { await ScreenshotCaptureService().savePng(Uint8List.fromList(capture.bytes!), title: capture.title, url: capture.url, prefix: 'zyro_fullpage', type: 'full_page'); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full screenshot saved as image'), behavior: SnackBarBehavior.floating)); } else if (choice == 'pdf') { await ScreenshotPdfExportService().savePaginated(Uint8List.fromList(capture.bytes!), capture.url); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full screenshot saved as PDF'), behavior: SnackBarBehavior.floating)); } } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Full capture failed: $e'), behavior: SnackBarBehavior.floating)); }
        },
      ),
      const SizedBox(height: 10),
      ScreenshotMiniActionButton(
        visible: controller.expanded,
        icon: LucideIcons.image,
        tooltip: 'Current page screenshot',
        onTap: () async {
          controller.collapse();
          if (kDebugMode)
            debugPrint('[SCREENSHOT PRO] Current page screenshot icon tapped');
          try { await ScreenshotCaptureService().captureVisible(controller: tab.controller!, title: tab.title ?? 'Website page', url: tab.url); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Screenshot saved to storage'), behavior: SnackBarBehavior.floating)); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e'), behavior: SnackBarBehavior.floating)); }
        },
      ),
      const SizedBox(height: 10),
      FloatingActionButton.small(
        heroTag: 'screenshot_pro_fab',
        tooltip: 'Screenshot Pro',
        onPressed: () {
          if (kDebugMode)
            debugPrint('[SCREENSHOT PRO] Screenshot floating camera tapped');
          controller.toggleExpanded();
        },
        child: const Icon(LucideIcons.camera),
      ),
    ],
  );
}

class ScreenshotMiniActionButton extends StatelessWidget {
  final bool visible;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const ScreenshotMiniActionButton({
    super.key,
    required this.visible,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: visible ? 1 : 0,
    duration: const Duration(milliseconds: 160),
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      child: FloatingActionButton.small(
        heroTag: tooltip,
        tooltip: tooltip,
        onPressed: visible ? onTap : null,
        child: Icon(icon, size: 19),
      ),
    ),
  );
}

Future<String?> _showSaveDialog(BuildContext context) => showDialog<String>(context: context, builder: (d) { final theme = Theme.of(d); return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)), contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 12), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: CircleAvatar(radius: 22, backgroundColor: theme.colorScheme.primary.withOpacity(.12), child: Icon(LucideIcons.image, color: theme.colorScheme.primary))), const SizedBox(height: 14), Text('Save Full Screenshot', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text('Choose the format for your captured full-page screenshot.', style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(.6))), const SizedBox(height: 18), _formatTile(d, LucideIcons.image, 'Save as Image', 'Best for sharing or viewing in gallery', 'image', true), const SizedBox(height: 9), _formatTile(d, LucideIcons.fileText, 'Save as PDF', 'Best for documents and scrolling pages', 'pdf', false), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')))])); });
Widget _formatTile(BuildContext c, IconData icon, String title, String subtitle, String value, bool primary) { final t = Theme.of(c); return InkWell(onTap: () => Navigator.pop(c, value), borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: primary ? t.colorScheme.primary.withOpacity(.1) : t.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: primary ? t.colorScheme.primary : t.dividerColor.withOpacity(.35))), child: Row(children: [Icon(icon, color: primary ? t.colorScheme.primary : t.colorScheme.onSurface), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)), Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: t.colorScheme.onSurface.withOpacity(.55)))])), Icon(LucideIcons.chevronRight, size: 17, color: t.colorScheme.onSurface.withOpacity(.35))]))); }
