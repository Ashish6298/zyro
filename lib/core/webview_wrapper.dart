import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'tab_manager.dart';
import 'browser_data_manager.dart';
import 'extension_manager.dart';
import 'models/tab_model.dart';
import '../engine/script_engine.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  bool _lastAdBlockState = false;
  bool _lastDownloaderState = false;

  @override
  Widget build(BuildContext context) {
    final extensionManager = context.watch<ExtensionManager>();
    final isAdBlockerEnabled = extensionManager.isExtensionEnabled('ad_blocker');
    final isVideoDownloaderEnabled = extensionManager.isExtensionEnabled('video_downloader');
    
    // Sync script engine state
    widget.scriptEngine.isAdBlockerEnabled = isAdBlockerEnabled;
    widget.scriptEngine.isVideoDownloaderEnabled = isVideoDownloaderEnabled;

    // Immediate injection if toggled ON
    if (isVideoDownloaderEnabled && !_lastDownloaderState) {
      widget.tab.controller?.evaluateJavascript(source: widget.scriptEngine.videoDownloaderScript);
    }
    _lastAdBlockState = isAdBlockerEnabled;
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.download, color: Colors.cyanAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DOWNLOAD OPTIONS',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.cyanAccent,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _buildDownloadSection(title, 'VIDEO QUALITY', [
              '144p', '360p', '720p (HD)', '1080p (FHD)', '4K (Ultra HD)'
            ], Colors.cyanAccent, url, sourceUrl: sourceUrl, pageUrl: pageUrl, isYouTube: isYouTube),
            const SizedBox(height: 16),
            _buildDownloadSection(title, 'AUDIO ONLY', [
              'MP3 (128kbps)', 'MP3 (320kbps)'
            ], Colors.purpleAccent, url, sourceUrl: sourceUrl, pageUrl: pageUrl, isYouTube: isYouTube),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection(
    String videoTitle,
    String sectionTitle,
    List<String> options,
    Color color,
    String url, {
    String? sourceUrl,
    String? pageUrl,
    bool isYouTube = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: GoogleFonts.shareTechMono(
            color: color.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.read<BrowserDataManager>().addDownload(
                    url,
                    title: videoTitle,
                    resolution: opt,
                    sourceUrl: sourceUrl,
                    pageUrl: pageUrl,
                    isYouTube: isYouTube,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(LucideIcons.download, color: Colors.cyanAccent, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Downloading $videoTitle ($opt)...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0F172A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    opt,
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
