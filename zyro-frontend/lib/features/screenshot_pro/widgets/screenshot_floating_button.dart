import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScreenshotFloatingButton extends StatelessWidget {
  const ScreenshotFloatingButton({super.key});
  @override
  Widget build(BuildContext context) => Positioned(
    right: 22,
    bottom: 126,
    child: FloatingActionButton.small(
      heroTag: 'screenshot_pro_fab',
      tooltip: 'Screenshot Pro',
      onPressed: () {
        if (kDebugMode)
          debugPrint('[SCREENSHOT PRO] Floating screenshot icon tapped');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot Pro is ready'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: const Icon(LucideIcons.camera),
    ),
  );
}
