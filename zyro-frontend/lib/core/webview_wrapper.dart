import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'tab_manager.dart';
import 'browser_data_manager.dart';
import 'extension_manager.dart';
import 'models/tab_model.dart';
import 'models/link_metadata.dart';
import '../app/widgets/link_context_menu_sheet.dart';
import '../engine/script_engine.dart';
import '../features/video_downloader/widgets/quality_selector_sheet.dart';

import '../features/video_downloader/controllers/download_controller.dart';
import '../features/video_downloader/services/video_detection_service.dart';
import '../features/extensions/dev_tools/dev_tools_controller.dart';
import '../features/extensions/dev_tools/dev_tools_service.dart';
import '../features/extensions/dev_tools/dev_tools_models.dart';

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
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
          source: """
            window.lastTouchX = 0;
            window.lastTouchY = 0;
            window.lastContextMenuTarget = null;
            window.addEventListener('touchstart', function(e) {
              if (e.touches && e.touches.length > 0) {
                window.lastTouchX = e.touches[0].clientX;
                window.lastTouchY = e.touches[0].clientY;
                window.lastContextMenuTarget = e.target;
              }
            }, true);
            window.addEventListener('mousedown', function(e) {
              window.lastTouchX = e.clientX;
              window.lastTouchY = e.clientY;
              window.lastContextMenuTarget = e.target;
            }, true);
            window.addEventListener('contextmenu', function(e) {
              window.lastContextMenuTarget = e.target;
              if (e.clientX || e.clientY) {
                window.lastTouchX = e.clientX;
                window.lastTouchY = e.clientY;
              }
            }, true);
          """,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
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
        useOnLoadResource: true,
        safeBrowsingEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        incognito: widget.tab.isIncognito,
        cacheEnabled: !widget.tab.isIncognito,
        clearSessionCache: widget.tab.isIncognito,
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
      onLongPressHitTestResult: (controller, hitTestResult) async {
        HapticFeedback.heavyImpact();

        final nativeUrl = hitTestResult.extra;

        // Try JS-based element retrieval at coordinate / contextmenu target
        Map<String, dynamic>? jsResult;
        try {
          final dynamic evalValue = await controller.evaluateJavascript(source: """
            (function() {
              var el = window.lastContextMenuTarget;
              if (!el) {
                var x = window.lastTouchX || 0;
                var y = window.lastTouchY || 0;
                el = document.elementFromPoint(x, y);
              }
              if (!el) return null;

              var anchor = el.closest('a');
              if (anchor && anchor.getAttribute('href')) {
                var href = anchor.href;
                var text = anchor.innerText || anchor.textContent || "";
                var title = anchor.getAttribute('title') || "";
                var imgInside = anchor.querySelector('img');
                var imageSrcIfInsideLink = imgInside ? imgInside.src : null;
                if (!text.trim() && imgInside) {
                  text = imgInside.alt || imgInside.title || "";
                }
                return {
                  "type": "link",
                  "url": href,
                  "title": text.trim() || title.trim() || href,
                  "imageSrcIfInsideLink": imageSrcIfInsideLink
                };
              }

              var img = el.closest('img') || el.closest('image');
              if (img) {
                return {
                  "type": "image",
                  "url": img.src,
                  "title": img.alt || img.title || "Image"
                };
              }

              return null;
            })();
          """);

          if (evalValue != null) {
            jsResult = Map<String, dynamic>.from(evalValue as Map);
          }
        } catch (e) {
          print("Error evaluating JS for long press: $e");
        }

        // Determine final link metadata properties
        String finalUrl = '';
        String finalTitle = '';
        LinkType type = LinkType.hyperlink;
        String? imageSrcIfInsideLink;

        if (jsResult != null) {
          finalUrl = jsResult['url'] ?? '';
          finalTitle = jsResult['title'] ?? '';
          finalUrl = finalUrl.trim();
          finalTitle = finalTitle.trim();

          final isJsImage = jsResult['type'] == 'image';
          if (isJsImage) {
            type = LinkType.image;
          } else {
            type = LinkType.hyperlink;
            imageSrcIfInsideLink = jsResult['imageSrcIfInsideLink'];
          }
        }

        // Fallback to native hitTestResult if JS extraction yielded nothing
        if (finalUrl.isEmpty && nativeUrl != null && nativeUrl.trim().isNotEmpty) {
          finalUrl = nativeUrl.trim();
          if (hitTestResult.type == InAppWebViewHitTestResultType.IMAGE_TYPE) {
            type = LinkType.image;
          } else {
            type = LinkType.hyperlink;
          }
        }

        final isDevToolsEnabled = extensionManager.isExtensionEnabled('dev_tools');
        if (isDevToolsEnabled) {
          try {
            final dynamic elementEval = await controller.evaluateJavascript(source: DevToolsService.getElementInfoScript);
            if (elementEval != null) {
              final elementMap = Map<String, dynamic>.from(elementEval as Map);
              final info = SelectedElementInfo.fromMap(elementMap);
              if (mounted) {
                context.read<DevToolsController>().setSelectedElement(info);
              }
              if (finalUrl.isEmpty) {
                finalUrl = info.href ?? info.src ?? widget.tab.url;
                finalTitle = '<${info.tagName}>';
              }
            }
          } catch (e) {
            print("Error retrieving element for DevTools: $e");
          }
        }

        // If still no valid URL, ignore
        if (finalUrl.isEmpty && !isDevToolsEnabled) {
          print("[CONTEXT MENU DEBUG] No valid URL detected. Skipping menu.");
          return;
        }

        // Handle protocols
        if (finalUrl.startsWith('mailto:')) {
          type = LinkType.email;
        } else if (finalUrl.startsWith('tel:')) {
          type = LinkType.phone;
        } else if (finalUrl.toLowerCase().endsWith('.pdf')) {
          type = LinkType.pdf;
        } else if (finalUrl.toLowerCase().endsWith('.mp4') || finalUrl.toLowerCase().endsWith('.mp3') || finalUrl.toLowerCase().endsWith('.webm')) {
          type = LinkType.video;
        } else if (finalUrl.toLowerCase().endsWith('.zip') || finalUrl.toLowerCase().endsWith('.apk') || finalUrl.toLowerCase().endsWith('.dmg')) {
          type = LinkType.download;
        }

        // Extract Domain
        String domain = '';
        try {
          final uri = Uri.parse(finalUrl);
          domain = uri.host.replaceAll('www.', '');
        } catch (_) {}

        if (finalTitle.isEmpty) {
          finalTitle = domain.isNotEmpty ? domain : 'Link Address';
        }

        // Log context menu debug info
        print("[CONTEXT MENU DEBUG] Detected Element Type: ${jsResult != null ? jsResult['type'] : 'Native HitTest'}");
        print("[CONTEXT MENU DEBUG] Final Selected URL: $finalUrl");
        print("[CONTEXT MENU DEBUG] Parent Anchor Found: ${jsResult != null && jsResult['type'] == 'link'}");
        print("[CONTEXT MENU DEBUG] Link Text / Title: $finalTitle");
        print("[CONTEXT MENU DEBUG] Image Source (if inside link): $imageSrcIfInsideLink");

        final metadata = LinkMetadata(
          url: finalUrl,
          title: finalTitle,
          domain: domain,
          type: type,
          imageSrcIfInsideLink: imageSrcIfInsideLink,
        );

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.55),
          builder: (context) => LinkContextMenuPopup(
            metadata: metadata,
            isIncognitoContext: widget.tab.isIncognito,
          ),
        );
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
        final canGoBack = await controller.canGoBack();
        final canGoForward = await controller.canGoForward();
        tabManager.updateTab(
          widget.tab.id,
          url: url.toString(),
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        );
        await widget.scriptEngine.onPageStart(controller, url);
      },
      onLoadStop: (controller, url) async {
        final tabManager = context.read<TabManager>();
        final dataManager = context.read<BrowserDataManager>();
        
        final title = await controller.getTitle() ?? "New Tab";
        final canGoBack = await controller.canGoBack();
        final canGoForward = await controller.canGoForward();
        
        tabManager.updateTab(
          widget.tab.id,
          url: url.toString(),
          progress: 1.0,
          title: title,
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        );
        if (!widget.tab.isIncognito) {
          dataManager.addHistory(url.toString(), title);
        }
        
        // Restore scroll position if saved
        if (widget.tab.scrollX != null && widget.tab.scrollY != null) {
          try {
            await controller.scrollTo(
              x: widget.tab.scrollX!.toInt(),
              y: widget.tab.scrollY!.toInt(),
            );
          } catch (e) {
            print("Error restoring scroll position: $e");
          }
        }
        
        await widget.scriptEngine.onPageFinished(controller, url);
      },
      onProgressChanged: (controller, progress) {
        final tabManager = context.read<TabManager>();
        tabManager.updateTab(widget.tab.id, progress: progress / 100.0);
      },
      onUpdateVisitedHistory: (controller, url, isReload) async {
        final tabManager = context.read<TabManager>();
        final canGoBack = await controller.canGoBack();
        final canGoForward = await controller.canGoForward();
        tabManager.updateTab(
          widget.tab.id,
          url: url.toString(),
          canGoBack: canGoBack,
          canGoForward: canGoForward,
        );
        await widget.scriptEngine.onUrlChanged(controller, url);
      },
      onScrollChanged: (controller, x, y) {
        if (!widget.tab.isIncognito) {
          context.read<TabManager>().updateTabScroll(
            widget.tab.id,
            x.toDouble(),
            y.toDouble(),
          );
        }
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
      onLoadResource: (controller, resource) {
        if (context.read<ExtensionManager>().isExtensionEnabled('dev_tools')) {
          final type = resource.initiatorType ?? 'other';
          context.read<DevToolsController>().addNetworkLog(
            resource.url?.toString() ?? '',
            'GET',
            type,
            statusCode: 200,
          );
        }
      },
      onReceivedError: (controller, request, error) {
        print("WebView Error: ${error.description}");
        if (context.read<ExtensionManager>().isExtensionEnabled('dev_tools')) {
          context.read<DevToolsController>().addConsoleLog(
            "WebView Error: ${error.description}",
            ConsoleLogType.error,
          );
          context.read<DevToolsController>().addNetworkLog(
            request.url.toString(),
            request.method ?? 'GET',
            'document',
            statusCode: 0,
          );
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) {
        print("HTTP Error: ${errorResponse.statusCode}");
        if (context.read<ExtensionManager>().isExtensionEnabled('dev_tools')) {
          context.read<DevToolsController>().addConsoleLog(
            "HTTP Error ${errorResponse.statusCode} on ${request.url}",
            ConsoleLogType.error,
          );
          context.read<DevToolsController>().addNetworkLog(
            request.url.toString(),
            request.method ?? 'GET',
            'document',
            statusCode: errorResponse.statusCode,
          );
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("Console: ${consoleMessage.message}");
        if (context.read<ExtensionManager>().isExtensionEnabled('dev_tools')) {
          ConsoleLogType logType = ConsoleLogType.log;
          if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
            logType = ConsoleLogType.error;
          } else if (consoleMessage.messageLevel == ConsoleMessageLevel.WARNING) {
            logType = ConsoleLogType.warn;
          } else if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
            logType = ConsoleLogType.log;
          } else if (consoleMessage.messageLevel == ConsoleMessageLevel.TIP) {
            logType = ConsoleLogType.info;
          }
          context.read<DevToolsController>().addConsoleLog(
            consoleMessage.message,
            logType,
          );
        }
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
