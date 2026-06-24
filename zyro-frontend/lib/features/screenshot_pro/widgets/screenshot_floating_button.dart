import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/screenshot_pro_controller.dart';
import '../../../core/models/tab_model.dart';
import '../services/screenshot_capture_service.dart';
import '../services/full_page_capture_service.dart';

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
          try { await FullPageCaptureService().capture(controller: tab.controller!, title: tab.title ?? 'Website page', url: tab.url); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Full screenshot saved to storage'), behavior: SnackBarBehavior.floating)); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Full capture failed: $e'), behavior: SnackBarBehavior.floating)); }
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
