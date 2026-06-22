import 'package:flutter/material.dart';
import '../../../../core/models/tab_model.dart';
import '../../../../core/webview_wrapper.dart';
import '../../../../engine/script_engine.dart';
import '../floating_videos_controller.dart';

class FloatingVideoPipView extends StatelessWidget {
  final TabModel tab;
  final ScriptEngine scriptEngine;
  final FloatingVideosController floatingCtrl;

  const FloatingVideoPipView({
    super.key,
    required this.tab,
    required this.scriptEngine,
    required this.floatingCtrl,
  });

  @override
  Widget build(BuildContext context) {
    print("[FLOATING VIDEO DEBUG] PiP render mode enabled");
    print("[FLOATING VIDEO DEBUG] Normal browser UI skipped");

    final video = floatingCtrl.activeVideo;

    // Determine video bounds - prefer current, fall back to cached
    Map<String, dynamic> rect = {};
    if (video != null && video.boundingRect.isNotEmpty) {
      final w = (video.boundingRect['width'] ?? 0.0).toDouble();
      final h = (video.boundingRect['height'] ?? 0.0).toDouble();
      if (w > 0 && h > 0) {
        rect = video.boundingRect;
        print("[FLOATING VIDEO DEBUG] Using current video bounds: w=$w, h=$h");
      }
    }
    if (rect.isEmpty && floatingCtrl.lastKnownBoundingRect.isNotEmpty) {
      final w = (floatingCtrl.lastKnownBoundingRect['width'] ?? 0.0).toDouble();
      final h = (floatingCtrl.lastKnownBoundingRect['height'] ?? 0.0).toDouble();
      if (w > 0 && h > 0) {
        rect = floatingCtrl.lastKnownBoundingRect;
        print("[FLOATING VIDEO DEBUG] Using cached video dimensions: w=$w, h=$h");
      }
    }

    Widget webViewWidget = WebViewWrapper(
      key: ValueKey(tab.id),
      tab: tab,
      scriptEngine: scriptEngine,
    );

    if (rect.isNotEmpty) {
      final vx = (rect['x'] ?? 0.0).toDouble();
      final vy = (rect['y'] ?? 0.0).toDouble();
      final vw = (rect['width'] ?? 0.0).toDouble();
      final vh = (rect['height'] ?? 0.0).toDouble();
      print("[FLOATING VIDEO DEBUG] video bounds detected: x=$vx, y=$vy, w=$vw, h=$vh");

      if (vw > 0 && vh > 0) {
        final ratio = vw / vh;
        print("[FLOATING VIDEO DEBUG] video aspect ratio calculated: $ratio. video aspect ratio applied.");
        final size = MediaQuery.of(context).size;
        final screenW = size.width;
        final screenH = size.height;

        webViewWidget = AspectRatio(
          aspectRatio: ratio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / vw;
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(-vx, -vy),
                      child: SizedBox(
                        width: screenW,
                        height: screenH,
                        child: WebViewWrapper(
                          key: ValueKey(tab.id),
                          tab: tab,
                          scriptEngine: scriptEngine,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    } else {
      print("[FLOATING VIDEO DEBUG] No valid video bounds available, showing fullscreen WebView");
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: webViewWidget),
    );
  }
}
