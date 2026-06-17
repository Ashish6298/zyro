import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'tab_manager.dart';
import 'browser_data_manager.dart';
import 'extension_manager.dart';
import 'models/tab_model.dart';
import '../engine/script_engine.dart';
import '../features/video_downloader/widgets/quality_selector_sheet.dart';

import '../features/video_downloader/controllers/download_controller.dart';
import '../features/video_downloader/services/video_detection_service.dart';

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
  bool _lastDownloaderState = false;

  @override
  Widget build(BuildContext context) {
    final extensionManager = context.watch<ExtensionManager>();
    final isAdBlockerEnabled = extensionManager.isExtensionEnabled('ad_blocker_downloader');
    final isVideoDownloaderEnabled = extensionManager.isExtensionEnabled('ad_blocker_downloader');
    
    // Sync script engine state
    widget.scriptEngine.isAdBlockerEnabled = isAdBlockerEnabled;
    widget.scriptEngine.isVideoDownloaderEnabled = isVideoDownloaderEnabled;

    // Immediate injection if toggled ON
    if (isVideoDownloaderEnabled && !_lastDownloaderState) {
      widget.tab.controller?.evaluateJavascript(source: widget.scriptEngine.videoDownloaderScript);
    }
    _lastDownloaderState = isVideoDownloaderEnabled;

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
        contentBlockers: isAdBlockerEnabled ? [
          ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: ".*googleadservices.*"),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
          ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: ".*doubleclick.net.*"),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
          ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: ".*ads.google.com.*"),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
          ContentBlocker(
            trigger: ContentBlockerTrigger(urlFilter: ".*googlesyndication.com.*"),
            action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
          ),
        ] : [],
      ),
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
      onWebViewCreated: (controller) {
        widget.tab.controller = controller;
        
        // Register JavaScript handler for video downloader
        controller.addJavaScriptHandler(
          handlerName: 'triggerDownload',
          callback: (args) {
            final data = args[0];
            _showDownloadPopup(
              context,
              data['url'],
              data['title'],
              sourceUrl: data['sourceUrl'],
              pageUrl: data['pageUrl'],
              isYouTube: data['isYouTube'] == true,
            );
          },
        );

        controller.addJavaScriptHandler(
          handlerName: 'updatePlayingVideo',
          callback: (args) {
            if (!mounted) return;
            final data = args[0];
            final downloadCtrl = context.read<DownloadController>();
            if (data == null) {
              downloadCtrl.updateCurrentPlayingVideo(null);
            } else {
              final service = VideoDetectionService();
              final playingVideo = service.parseVideoState(Map<String, dynamic>.from(data));
              downloadCtrl.updateCurrentPlayingVideo(playingVideo);
            }
          },
        );
      },
      onLoadStart: (controller, url) async {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, url: url.toString());
        await widget.scriptEngine.onPageStart(controller, url);
      },
      onLoadStop: (controller, url) async {
        final tabManager = context.read<TabManager>();
        final dataManager = context.read<BrowserDataManager>();
        
        final title = await controller.getTitle() ?? "New Tab";
        tabManager.updateTab(widget.tab.id, url: url.toString(), progress: 1.0, title: title);
        dataManager.addHistory(url.toString(), title);
        
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
      onDownloadStartRequest: (controller, downloadRequest) async {
        final dataManager = context.read<BrowserDataManager>();
        dataManager.addDownload(
          downloadRequest.url.toString(),
          title: downloadRequest.suggestedFilename ?? 'Video Download',
          suggestedFileName: downloadRequest.suggestedFilename,
          mimeType: downloadRequest.mimeType,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download started: ${downloadRequest.suggestedFilename ?? 'file'}"),
            backgroundColor: Colors.cyanAccent.withOpacity(0.8),
          ),
        );
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

  void _showDownloadPopup(
    BuildContext context,
    String url,
    String title, {
    String? sourceUrl,
    String? pageUrl,
    bool isYouTube = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QualitySelectorSheet(
        url: pageUrl ?? url,
        title: title,
      ),
    );
  }
}
