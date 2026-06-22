import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../floating_video_models.dart';
import 'speed_control_sheet.dart';
import 'transparency_control.dart';

class FloatingVideoControls extends StatelessWidget {
  final FloatingVideoModel video;
  final double currentOpacity;
  final double currentSpeed;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onSeek;

  const FloatingVideoControls({
    super.key,
    required this.video,
    required this.currentOpacity,
    required this.currentSpeed,
    required this.onPlayPause,
    required this.onClose,
    required this.onSpeedChanged,
    required this.onOpacityChanged,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDuration = video.duration > 0;
    final progress = hasDuration ? (video.currentTime / video.duration).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Top controls: Title & Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    video.videoTitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.close, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Middle Play/Pause button
          Center(
            child: IconButton(
              icon: Icon(
                video.isPlaying ? LucideIcons.pause : LucideIcons.play,
                color: Colors.white,
                size: 28,
              ),
              onPressed: onPlayPause,
            ),
          ),
          
          const Spacer(),

          // Bottom control options: Speed, Opacity, Seek bar
          Column(
            children: [
              // Mini Seek Bar
              if (hasDuration)
                GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPos = box.globalToLocal(details.globalPosition);
                      final pct = (localPos.dx / box.size.width).clamp(0.0, 1.0);
                      onSeek(pct * video.duration);
                    }
                  },
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 3,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.2),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Speed Selector
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SpeedControlSheet(
                            currentSpeed: currentSpeed,
                            onSpeedSelected: onSpeedChanged,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(LucideIcons.gauge, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${currentSpeed}x',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Opacity Selector
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => TransparencyControl(
                            currentOpacity: currentOpacity,
                            onOpacityChanged: onOpacityChanged,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.opacity, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${(currentOpacity * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
