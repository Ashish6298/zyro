import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/browser_data_manager.dart';
import '../../video_player/screens/local_video_player_screen.dart';
import '../controllers/download_controller.dart';
import '../services/format_mapper_service.dart';
import '../services/url_sanitizer_service.dart';

class QualitySelectorSheet extends StatefulWidget {
  final String url;
  final String title;

  const QualitySelectorSheet({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<QualitySelectorSheet> createState() => _QualitySelectorSheetState();
}

class _QualitySelectorSheetState extends State<QualitySelectorSheet> {
  bool _isLoading = true;
  String? _error;
  List<UiFormatOption> _options = [];

  @override
  void initState() {
    super.initState();
    _loadFormats();
  }

  Future<void> _loadFormats() async {
    try {
      final controller = context.read<DownloadController>();
      final formats = await controller.fetchAvailableFormats(widget.url);
      if (mounted) {
        setState(() {
          _options = formats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = context.read<DownloadController>();
    final dataManager = context.read<BrowserDataManager>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.download, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DOWNLOAD OPTIONS',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (!_isLoading)
                  IconButton(
                    icon: Icon(LucideIcons.refreshCw, color: theme.colorScheme.onBackground.withOpacity(0.5), size: 16),
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadFormats();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(color: theme.colorScheme.onBackground, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _options.length,
                  separatorBuilder: (context, index) => Divider(color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.4)),
                  itemBuilder: (context, idx) {
                    final opt = _options[idx];
                    final isAudio = opt.type == 'audio';
                    final color = isAudio ? Colors.purple : theme.colorScheme.primary;

                    final cleanUrl = UrlSanitizerService.sanitizeSingleVideoUrl(widget.url);
                    final videoId = UrlSanitizerService.extractVideoId(cleanUrl);
                    final downloaded = controller.isDownloaded(videoId, opt.label);
                    final downloading = controller.isDownloading(videoId, opt.label);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(isAudio ? LucideIcons.music : LucideIcons.video, color: color, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.label,
                              style: GoogleFonts.outfit(color: theme.colorScheme.onBackground, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (downloaded)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SAVED',
                                style: GoogleFonts.outfit(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (downloading)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.outfit(color: theme.colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        opt.description,
                        style: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.4), fontSize: 12),
                      ),
                      trailing: Icon(LucideIcons.chevronRight, color: theme.colorScheme.onBackground.withOpacity(0.3)),
                      onTap: () {
                        if (downloaded) {
                          final downloadedVideo = controller.getDownloadedVideo(videoId, opt.label);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: theme.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text(
                                'ALREADY DOWNLOADED',
                                style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                'This resolution has already been saved to your local storage. Would you like to play it now or download again?',
                                style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Close sheet
                                    if (downloadedVideo != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LocalVideoPlayerScreen(
                                            filePath: downloadedVideo.localFilePath,
                                            title: downloadedVideo.title,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text('PLAY IN APP', style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    controller.startBackendDownload(
                                      pageUrl: widget.url,
                                      title: widget.title,
                                      option: opt,
                                      dataManager: dataManager,
                                    );
                                    Navigator.pop(context); // Close sheet
                                  },
                                  child: Text('DOWNLOAD AGAIN', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                ),
                              ],
                            ),
                          );
                        } else if (downloading) {
                          final req = controller.getActiveRequest(videoId, opt.label);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Download already in progress: ${((req?.progress ?? 0) * 100).toInt()}%'),
                              backgroundColor: theme.colorScheme.primary,
                            ),
                          );
                        } else {
                          controller.startBackendDownload(
                            pageUrl: widget.url,
                            title: widget.title,
                            option: opt,
                            dataManager: dataManager,
                          );
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
