import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../video_downloader/models/downloaded_video.dart';

class DownloadedVideoCard extends StatelessWidget {
  final DownloadedVideo video;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const DownloadedVideoCard({
    super.key,
    required this.video,
    required this.onPlay,
    required this.onDelete,
  });

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double wBytes = bytes.toDouble();
    while (wBytes >= 1024 && i < suffixes.length - 1) {
      wBytes /= 1024;
      i++;
    }
    return '${wBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (duration.inHours > 0) {
      return '${duration.inHours}:${twoDigits(minutes)}:${twoDigits(secs)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(secs)}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final file = File(video.localFilePath);
    final fileExists = file.existsSync();

    return Container(
      height: 96,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fileExists 
              ? theme.dividerColor.withOpacity(isDark ? 0.1 : 0.4) 
              : theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail area
            Container(
              width: 100,
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (video.thumbnailPath.isNotEmpty && video.thumbnailPath.startsWith('http'))
                    Image.network(
                      video.thumbnailPath,
                      fit: BoxFit.cover,
                      width: 100,
                      height: double.infinity,
                      errorBuilder: (context, _, __) => Icon(LucideIcons.video, color: theme.colorScheme.primary, size: 28),
                    )
                  else
                    Icon(LucideIcons.video, color: theme.colorScheme.primary, size: 28),
                  if (video.duration > 0)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (!fileExists)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Icon(LucideIcons.alertOctagon, color: theme.colorScheme.error, size: 24),
                      ),
                    ),
                ],
              ),
            ),
            // Content details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: fileExists ? theme.colorScheme.onBackground : theme.colorScheme.onBackground.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.quality,
                            style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatSize(video.fileSize),
                          style: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.4), fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(video.downloadedAt),
                          style: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.4), fontSize: 10),
                        ),
                      ],
                    ),
                    if (!fileExists)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          'Missing file error',
                          style: GoogleFonts.outfit(color: theme.colorScheme.error, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              width: 48,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.3)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: fileExists ? onPlay : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        LucideIcons.play,
                        color: fileExists ? Colors.green : theme.colorScheme.onBackground.withOpacity(0.2),
                        size: 20,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        LucideIcons.trash2,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
