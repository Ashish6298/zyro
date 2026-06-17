import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../controllers/download_controller.dart';
import 'quality_selector_sheet.dart';

class FloatingDownloadButton extends StatelessWidget {
  const FloatingDownloadButton({super.key});

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.cyanAccent,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
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
