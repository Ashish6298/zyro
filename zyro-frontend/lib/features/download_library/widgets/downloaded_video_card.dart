import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../video_downloader/models/downloaded_video.dart';

class DownloadedVideoCard extends StatefulWidget {
  final DownloadedVideo video;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const DownloadedVideoCard({
    super.key,
    required this.video,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  State<DownloadedVideoCard> createState() => _DownloadedVideoCardState();
}

class _DownloadedVideoCardState extends State<DownloadedVideoCard> {
  double _scale = 1.0;

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
    final file = File(widget.video.localFilePath);
    final fileExists = file.existsSync();

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: fileExists
                  ? (isDark ? theme.dividerColor.withOpacity(0.06) : theme.dividerColor.withOpacity(0.4))
                  : theme.colorScheme.error.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Widescreen Thumbnail
                GestureDetector(
                  onTap: fileExists ? widget.onPlay : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 130,
                          height: 74,
                          color: isDark ? Colors.black38 : Colors.black.withOpacity(0.04),
                          child: widget.video.thumbnailPath.isNotEmpty && widget.video.thumbnailPath.startsWith('http')
                              ? Image.network(
                                  widget.video.thumbnailPath,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 74,
                                  errorBuilder: (context, _, __) => Icon(LucideIcons.video, color: theme.colorScheme.primary, size: 24),
                                )
                              : Icon(LucideIcons.video, color: theme.colorScheme.primary, size: 24),
                        ),
                      ),
                      // Gradient overlay for depth
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      if (widget.video.duration > 0)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatDuration(widget.video.duration),
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (!fileExists)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(LucideIcons.alertOctagon, color: theme.colorScheme.error, size: 24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Details & Action buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: fileExists ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.video.quality,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatSize(widget.video.fileSize),
                              style: GoogleFonts.outfit(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(widget.video.downloadedAt),
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (!fileExists)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Missing file error',
                            style: GoogleFonts.outfit(color: theme.colorScheme.error, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Premium Actions Stack
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play Action (Vibrant Circle)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: fileExists ? widget.onPlay : null,
                        borderRadius: BorderRadius.circular(22),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: fileExists
                                ? const LinearGradient(
                                    colors: [Color(0xFF34D399), Color(0xFF059669)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: fileExists ? null : theme.colorScheme.onSurface.withOpacity(0.05),
                            boxShadow: fileExists
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF34D399).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            LucideIcons.play,
                            color: fileExists ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.2),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Delete Action (Subtle Circle)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onDelete,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.error.withOpacity(0.08),
                            border: Border.all(
                              color: theme.colorScheme.error.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            LucideIcons.trash2,
                            color: theme.colorScheme.error.withOpacity(0.85),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
