import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../controllers/download_controller.dart';
import 'quality_selector_sheet.dart';

class FloatingDownloadButton extends StatelessWidget {
  const FloatingDownloadButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<DownloadController>(
      builder: (context, controller, child) {
        final video = controller.currentPlayingVideo;
        if (video == null) return const SizedBox.shrink();

        // Check if a download is active for this video
        final isDownloadingAny = controller.activeRequests.any((r) =>
            r.url == video.canonicalVideoUrl ||
            r.url == video.sourcePageUrl);

        double progress = 0.0;
        if (isDownloadingAny) {
          final req = controller.activeRequests.firstWhere((r) =>
              r.url == video.canonicalVideoUrl ||
              r.url == video.sourcePageUrl);
          progress = req.progress;
        }

        return Positioned(
          bottom: 110,
          right: 20,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => QualitySelectorSheet(
                  url: video.canonicalVideoUrl,
                  title: video.title,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isDownloadingAny)
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: progress > 0.0 ? progress : null,
                      strokeWidth: 4,
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.3),
                    ),
                  ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.tertiary, theme.colorScheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isDownloadingAny ? LucideIcons.loader : LucideIcons.download,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
