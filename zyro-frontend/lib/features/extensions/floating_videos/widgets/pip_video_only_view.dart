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
    final int width = floatingCtrl.lastKnownVideoWidth > 0 ? floatingCtrl.lastKnownVideoWidth : 1920;
    final int height = floatingCtrl.lastKnownVideoHeight > 0 ? floatingCtrl.lastKnownVideoHeight : 1080;
    final double ratio = width / height;

    Widget webViewWidget = WebViewWrapper(
      key: ValueKey(currentTab.id),
      tab: currentTab,
      scriptEngine: scriptEngine,
    );

    webViewWidget = AspectRatio(
      aspectRatio: ratio,
      child: webViewWidget,
    );

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
