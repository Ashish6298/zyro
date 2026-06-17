import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/browser_data_manager.dart';
import 'local_video_player_screen.dart';
import '../widgets/glass_container.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size >= 10 || unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
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
          style: GoogleFonts.shareTechMono(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.white24),
            onPressed: () => context.read<BrowserDataManager>().clearDownloads(),
          ),
        ],
      ),
      body: Consumer<BrowserDataManager>(
        builder: (context, dataManager, child) {
          final downloads = dataManager.downloads;

          if (downloads.isEmpty) {
            return Center(
              child: Text(
                'NO DOWNLOADS ACTIVE',
                style: GoogleFonts.shareTechMono(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final item = downloads[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 16,
                  opacity: 0.05,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: item.isCompleted && item.filePath != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocalVideoPlayerScreen(
                                  filePath: item.filePath!,
                                  title: item.title,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.isFailed
                                  ? LucideIcons.alertCircle
                                  : item.isCompleted
                                      ? LucideIcons.checkCircle
                                      : LucideIcons.download,
                              color: item.isFailed
                                  ? Colors.redAccent
                                  : item.isCompleted
                                      ? Colors.greenAccent
                                      : Colors.cyanAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.shareTechMono(
                                      color: Colors.white38,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (item.isCompleted)
                              const Icon(
                                LucideIcons.play,
                                color: Colors.greenAccent,
                                size: 18,
                              )
                            else
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: item.isFailed ? 0 : item.progress,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    item.isFailed ? Colors.redAccent : Colors.cyanAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.isFailed
                              ? '${item.resolution} | FAILED'
                              : '${item.resolution} | ${item.isCompleted ? 'COMPLETED' : '${(item.progress * 100).toInt()}%'}',
                          style: GoogleFonts.shareTechMono(
                            color: item.isFailed
                                ? Colors.redAccent.withValues(alpha: 0.75)
                                : item.isCompleted
                                    ? Colors.greenAccent.withValues(alpha: 0.5)
                                    : Colors.cyanAccent.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        if (!item.isCompleted && !item.isFailed) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 6,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.cyanAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.totalBytes != null
                                ? '${_formatBytes(item.downloadedBytes)} downloaded | ${_formatBytes(item.totalBytes! - item.downloadedBytes)} remaining'
                                : '${_formatBytes(item.downloadedBytes)} downloaded',
                            style: GoogleFonts.shareTechMono(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (item.isFailed && item.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.errorMessage!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
