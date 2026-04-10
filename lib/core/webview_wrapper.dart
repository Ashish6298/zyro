import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'tab_manager.dart';
import 'models/tab_model.dart';
import '../engine/script_engine.dart';

class WebViewWrapper extends StatefulWidget {
  final TabModel tab;
  final ScriptEngine scriptEngine;

  const WebViewWrapper({
    super.key,
    required this.tab,
    required this.scriptEngine,
  });

  @override
  State<WebViewWrapper> createState() => _WebViewWrapperState();
}

class _WebViewWrapperState extends State<WebViewWrapper> {
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.tab.url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        isInspectable: true,
        useShouldOverrideUrlLoading: true,
        javaScriptCanOpenWindowsAutomatically: true,
        supportMultipleWindows: true,
        allowsBackForwardNavigationGestures: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        useOnDownloadStart: true,
        safeBrowsingEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
      onWebViewCreated: (controller) {
        widget.tab.controller = controller;
      },
      onLoadStart: (controller, url) async {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, url: url.toString());
        await widget.scriptEngine.onPageStart(controller, url);
      },
      onLoadStop: (controller, url) async {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, url: url.toString(), progress: 1.0);
        await widget.scriptEngine.onPageFinished(controller, url);
      },
      onProgressChanged: (controller, progress) {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, progress: progress / 100.0);
      },
      onUpdateVisitedHistory: (controller, url, isReload) async {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, url: url.toString());
        await widget.scriptEngine.onUrlChanged(controller, url);
      },
      onReceivedError: (controller, request, error) {
        print("WebView Error: ${error.description}");
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        print("HTTP Error: ${errorResponse.statusCode}");
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("Console: ${consoleMessage.message}");
      },
      onTitleChanged: (controller, title) {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, title: title);
      },
    );
  }
}
