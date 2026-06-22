import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'ad_block_rule_engine.dart';
import 'ad_block_stats_service.dart';
import 'youtube_ad_blocker_service.dart';
import 'cosmetic_filter_injector.dart';
import '../../../../core/extension_manager.dart';

class AdBlockService {
  final AdBlockStatsService statsService;
  final ExtensionManager extensionManager;

  AdBlockService({
    required this.statsService,
    required this.extensionManager,
  });

  bool get isEnabled => extensionManager.isExtensionEnabled('ad_blocker_downloader');

  Future<WebResourceResponse?> interceptRequest({
    required String url,
    String? requestType,
    String? sourceUrl,
  }) async {
    if (!isEnabled) {
      // Log when disabled
      debugPrint("[ADBLOCK] Ignored request when Ad Blocker is disabled: $url");
      return null;
    }

    final result = AdBlockRuleEngine.match(url, requestType: requestType, sourceUrl: sourceUrl);
    if (result.isBlocked) {
      debugPrint("[ADBLOCK] Blocked request URL: $url | Matched rule: ${result.matchedRule} | Source website: ${result.sourceDomain}");
      
      // Record statistic
      await statsService.recordBlockedEvent(url);
      
      debugPrint("[ADBLOCK] Total blocked count: ${statsService.stats.totalBlocked} | Domain count updated: ${result.sourceDomain} -> ${statsService.stats.domainBlockedCounts[result.sourceDomain]}");

      // Return empty response to prevent loading
      return WebResourceResponse(
        contentType: _getContentTypeForUrl(url),
        data: Uint8List(0),
      );
    }
    return null;
  }

  String _getContentTypeForUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.js') || lower.contains('script')) return 'application/javascript';
    if (lower.contains('.css')) return 'text/css';
    if (lower.contains('.png') || lower.contains('.jpg') || lower.contains('.gif') || lower.contains('pixel')) return 'image/png';
    return 'text/plain';
  }

  String getInjectedScripts(String url) {
    if (!isEnabled) return "";
    
    final isYouTube = url.contains('youtube.com') || url.contains('youtu.be');
    final sb = StringBuffer();
    
    if (isYouTube) {
      debugPrint("[ADBLOCK] YouTube ad cleanup triggered for website: $url");
      sb.write(YouTubeAdBlockerService.cosmeticScript);
    } else {
      debugPrint("[ADBLOCK] Cosmetic element removed action triggered for website: $url");
      sb.write(CosmeticFilterInjector.cosmeticScript);
    }
    
    return sb.toString();
  }
}
