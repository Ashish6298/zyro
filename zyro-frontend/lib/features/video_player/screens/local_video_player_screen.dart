import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const LocalVideoPlayerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<LocalVideoPlayerScreen> createState() => _LocalVideoPlayerScreenState();
}

class _LocalVideoPlayerScreenState extends State<LocalVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'The video file could not be found. It may have been moved or deleted externally.';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });

      setState(() {
        _isInitialized = true;
      });
      _controller!.play();
      
      // Auto-hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller!.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _showControls = true;
      });
    } else {
      _controller!.play();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _controller!.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (duration.inHours > 0) {
      return '${duration.inHours}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    // Reset orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertOctagon, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'FILE NOT FOUND',
                style: GoogleFonts.shareTechMono(color: Colors.redAccent, fontSize: 20, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: Text('GO BACK', style: GoogleFonts.shareTechMono(letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showControls,
        child: Stack(
          children: [
            // Dark gradient backdrop
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Play/Pause Center Trigger
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller!.value.isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Bottom Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Video Progress bar
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.cyanAccent,
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                          style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _controller!.value.volume > 0.0 ? LucideIcons.volume2 : LucideIcons.volumeX,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                _controller!.setVolume(_controller!.value.volume > 0.0 ? 0.0 : 1.0);
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                _isFullscreen ? LucideIcons.minimize : LucideIcons.maximize,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _toggleFullscreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
