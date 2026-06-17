import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final VideoPlayerController _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath));
    _initializeFuture = _controller.initialize().then((_) {
      _controller.play();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: Colors.white),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_controller.value.isInitialized) {
            return Center(
              child: Text(
                'Unable to play video',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
            );
          }

          return Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.cyanAccent,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _controller.value.isPlaying ? 0 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
