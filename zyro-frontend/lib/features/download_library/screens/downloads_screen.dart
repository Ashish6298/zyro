import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../video_downloader/controllers/download_controller.dart';
import '../../video_downloader/models/download_request.dart';
import '../../video_player/screens/local_video_player_screen.dart';
import '../widgets/downloaded_video_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadController>().loadDownloadedVideos();
    });
  }

  String _formatState(DownloadState state) {
    switch (state) {
      case DownloadState.extracting:
        return 'EXTRACTING METADATA...';
      case DownloadState.downloadingVideo:
        return 'DOWNLOADING VIDEO TRACK...';
      case DownloadState.downloadingAudio:
        return 'DOWNLOADING AUDIO TRACK...';
      case DownloadState.merging:
        return 'MERGING AUDIO & VIDEO...';
      case DownloadState.completed:
        return 'COMPLETED';
      case DownloadState.failed:
        return 'FAILED';
      default:
        return 'QUEUED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'DOWNLOADS',
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Consumer<DownloadController>(
        builder: (context, controller, child) {
          final active = controller.activeRequests;
          final completed = controller.downloadedVideos;

          if (active.isEmpty && completed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.downloadCloud,
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'LIBRARY IS EMPTY',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your active and completed downloads will appear here.',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadDownloadedVideos,
            color: theme.colorScheme.primary,
            backgroundColor: theme.cardColor,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                if (active.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE DOWNLOADS',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.secondary,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${active.length}',
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.secondary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...active.map((req) => _buildActiveDownloadCard(context, req, controller, theme, isDark)),
                  const SizedBox(height: 16),
                ],
                if (completed.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DOWNLOADED VIDEOS',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${completed.length}',
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...completed.map((video) => DownloadedVideoCard(
                        video: video,
                        onPlay: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocalVideoPlayerScreen(
                                filePath: video.localFilePath,
                                title: video.title,
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: theme.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Row(
                                children: [
                                  Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete File?',
                                    style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Are you sure you want to permanently delete this downloaded video? This action cannot be undone.',
                                style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('CANCEL', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    controller.deleteVideo(video.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Video deleted successfully',
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        backgroundColor: theme.colorScheme.error,
                                      ),
                                    );
                                  },
                                  child: Text('DELETE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveDownloadCard(
    BuildContext context,
    DownloadRequest req,
    DownloadController controller,
    ThemeData theme,
    bool isDark,
  ) {
    final isFailed = req.state == DownloadState.failed;
    final progress = req.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFailed 
              ? theme.colorScheme.error.withOpacity(0.3) 
              : (isDark ? theme.dividerColor.withOpacity(0.06) : theme.dividerColor.withOpacity(0.4)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatState(req.state),
                      style: GoogleFonts.outfit(
                        color: isFailed ? theme.colorScheme.error : theme.colorScheme.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFailed ? LucideIcons.trash2 : LucideIcons.xCircle,
                  color: isFailed ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 16,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isFailed
                      ? theme.colorScheme.error.withOpacity(0.08)
                      : theme.colorScheme.onSurface.withOpacity(0.03),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () {
                  controller.removeFailedRequest(req.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: isFailed ? 0 : (progress > 0 ? progress : null),
                    color: theme.colorScheme.secondary,
                    backgroundColor: theme.dividerColor.withOpacity(isDark ? 0.08 : 0.15),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isFailed ? 'FAILED' : '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isFailed && req.error != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                req.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: theme.colorScheme.error, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
