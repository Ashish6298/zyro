import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'widgets/dev_tools_panel.dart';

class DevToolsExtension {
  static const String id = 'dev_tools';

  static void showPanel(BuildContext context, InAppWebViewController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DevToolsPanel(webViewController: controller),
    );
  }
}
