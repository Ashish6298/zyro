import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/tab_manager.dart';
import '../../../../core/webview_wrapper.dart';
import '../../../../engine/script_engine.dart';
import '../floating_videos_controller.dart';

class PipVideoOnlyView extends StatelessWidget {
  final ScriptEngine scriptEngine;

  const PipVideoOnlyView({
    super.key,
    required this.scriptEngine,
  });

  @override
  Widget build(BuildContext context) {
    final tabManager = context.watch<TabManager>();
    final currentTab = tabManager.currentTab;
    if (currentTab == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }

    final floatingCtrl = context.watch<FloatingVideosController>();
    final video = floatingCtrl.activeVideo;

    // Determine video bounds - prefer current, fall back to cached
    Map<String, dynamic> rect = {};
    if (video != null && video.boundingRect.isNotEmpty) {
      final w = (video.boundingRect['width'] ?? 0.0).toDouble();
      final h = (video.boundingRect['height'] ?? 0.0).toDouble();
      if (w > 0 && h > 0) {
        rect = video.boundingRect;
      }
    }
    if (rect.isEmpty && floatingCtrl.lastKnownBoundingRect.isNotEmpty) {
      final w = (floatingCtrl.lastKnownBoundingRect['width'] ?? 0.0).toDouble();
      final h = (floatingCtrl.lastKnownBoundingRect['height'] ?? 0.0).toDouble();
      if (w > 0 && h > 0) {
        rect = floatingCtrl.lastKnownBoundingRect;
      }
    }

    Widget webViewWidget = WebViewWrapper(
      key: ValueKey(currentTab.id),
      tab: currentTab,
      scriptEngine: scriptEngine,
    );

    if (rect.isNotEmpty) {
      final vx = (rect['x'] ?? 0.0).toDouble();
      final vy = (rect['y'] ?? 0.0).toDouble();
      final vw = (rect['width'] ?? 0.0).toDouble();
      final vh = (rect['height'] ?? 0.0).toDouble();

      if (vw > 0 && vh > 0) {
        final ratio = vw / vh;
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
                          key: ValueKey(currentTab.id),
                          tab: currentTab,
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
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Center(
          child: webViewWidget,
        ),
      ),
    );
  }
}
