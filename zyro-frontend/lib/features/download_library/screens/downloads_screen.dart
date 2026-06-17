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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DOWNLOADS',
          style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 20, letterSpacing: 2),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                  Icon(LucideIcons.downloadCloud, color: Colors.white.withValues(alpha: 0.1), size: 80),
                  const SizedBox(height: 16),
                  Text(
                    'NO DOWNLOADS',
                    style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 16, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your active and completed downloads will appear here.',
                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadDownloadedVideos,
            color: Colors.cyanAccent,
            backgroundColor: const Color(0xFF1E293B),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                if (active.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                    child: Text(
                      'ACTIVE DOWNLOADS (${active.length})',
                      style: GoogleFonts.shareTechMono(color: Colors.orangeAccent, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...active.map((req) => _buildActiveDownloadCard(context, req, controller)),
                  const SizedBox(height: 16),
                ],
                if (completed.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'DOWNLOADED VIDEOS (${completed.length})',
                      style: GoogleFonts.shareTechMono(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
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
                              backgroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text(
                                'DELETE DOWNLOAD',
                                style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 16, letterSpacing: 1),
                              ),
                              content: Text(
                                'Are you sure you want to delete this file and remove it from your library? This action cannot be undone.',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('CANCEL', style: GoogleFonts.shareTechMono(color: Colors.white54)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    controller.deleteVideo(video.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Video deleted successfully'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  },
                                  child: Text('DELETE', style: GoogleFonts.shareTechMono(color: Colors.redAccent)),
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

  Widget _buildActiveDownloadCard(BuildContext context, DownloadRequest req, DownloadController controller) {
    final isFailed = req.state == DownloadState.failed;
    final progress = req.progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFailed ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
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
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatState(req.state),
                      style: GoogleFonts.shareTechMono(
                        color: isFailed ? Colors.redAccent : Colors.orangeAccent,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFailed ? LucideIcons.trash2 : LucideIcons.xCircle,
                  color: isFailed ? Colors.redAccent : Colors.white38,
                  size: 20,
                ),
                onPressed: () {
                  if (isFailed) {
                    controller.removeFailedRequest(req.id);
                  } else {
                    // Cancel / remove from list
                    controller.removeFailedRequest(req.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isFailed ? 0 : (progress > 0 ? progress : null),
                    color: Colors.orangeAccent,
                    backgroundColor: Colors.white10,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isFailed ? 'FAILED' : '${(progress * 100).toInt()}%',
                style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (isFailed && req.error != null) ...[
            const SizedBox(height: 8),
            Text(
              req.error!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 11),
            ),
          ]
        ],
      ),
    );
  }
}
