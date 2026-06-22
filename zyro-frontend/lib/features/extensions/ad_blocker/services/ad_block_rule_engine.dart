class AdBlockInterceptResult {
  final bool isBlocked;
  final String? matchedRule;
  final String requestUrl;
  final String? requestType;
  final String sourceDomain;

  AdBlockInterceptResult({
    required this.isBlocked,
    this.matchedRule,
    required this.requestUrl,
    this.requestType,
    required this.sourceDomain,
  });
}

class AdBlockRuleEngine {
  static final List<Map<String, dynamic>> _rules = [
    {'name': 'DoubleClick', 'pattern': RegExp(r'doubleclick\.net')},
    {'name': 'Google Syndication', 'pattern': RegExp(r'googlesyndication\.com')},
    {'name': 'Google Ad Services', 'pattern': RegExp(r'googleadservices\.com')},
    {'name': 'Google Ad Service subdomain', 'pattern': RegExp(r'adservice\.google\.com')},
    {'name': 'PageAd endpoint', 'pattern': RegExp(r'/pagead/')},
    {'name': 'AdSystem keyword', 'pattern': RegExp(r'adsystem')},
    {'name': 'AdServer keyword', 'pattern': RegExp(r'adserver')},
    {'name': 'AdClick keyword', 'pattern': RegExp(r'adclick')},
    {'name': 'Telemetry tracking', 'pattern': RegExp(r'\btelemetry\b')},
    {'name': 'Analytics tracking', 'pattern': RegExp(r'\banalytics\b')},
    {'name': 'Amplitude analytics', 'pattern': RegExp(r'amplitude\.com')},
    {'name': 'Mixpanel analytics', 'pattern': RegExp(r'mixpanel\.com')},
    {'name': 'AppNexus ads', 'pattern': RegExp(r'adnxs\.com')},
    {'name': 'AdTech keyword', 'pattern': RegExp(r'adtech')},
    {'name': 'AdColony keyword', 'pattern': RegExp(r'adcolony')},
    {'name': 'Adsymptotic ads', 'pattern': RegExp(r'adsymptotic')},
    {'name': 'PubMatic ads', 'pattern': RegExp(r'pubmatic')},
    {'name': 'Rubicon Project ads', 'pattern': RegExp(r'rubiconproject')},
    {'name': 'OpenX ads', 'pattern': RegExp(r'openx\.net')},
    {'name': 'CasaleMedia ads', 'pattern': RegExp(r'casalemedia')},
    {'name': 'Outbrain recommendations', 'pattern': RegExp(r'outbrain')},
    {'name': 'Taboola recommendations', 'pattern': RegExp(r'taboola')},
    {'name': 'ScorecardResearch tracking', 'pattern': RegExp(r'scorecardresearch')},
    {'name': 'Quantserve tracking', 'pattern': RegExp(r'quantserve')},
    {'name': 'Criteo retargeting', 'pattern': RegExp(r'criteo')},
    {'name': 'Tracking pixels', 'pattern': RegExp(r'\bpixel\b')},
    {'name': 'Facebook tracking pixel', 'pattern': RegExp(r'facebook\.com/tr/')},
    {'name': 'Google Analytics', 'pattern': RegExp(r'google-analytics\.com')},
    {'name': 'Google Tag Manager', 'pattern': RegExp(r'googletagmanager\.com')},
    {'name': 'Google Tag Services', 'pattern': RegExp(r'googletagservices\.com')},
    {'name': 'YouTube Ads stats', 'pattern': RegExp(r'youtube\.com/api/stats/ads')},
    {'name': 'YouTube PageAd', 'pattern': RegExp(r'youtube\.com/pagead')},
    {'name': 'YouTube ptracking', 'pattern': RegExp(r'youtube\.com/ptracking')},
    {'name': 'YouTube midroll info', 'pattern': RegExp(r'youtube\.com/get_midroll_info')},
    {'name': 'YouTube activeview stats', 'pattern': RegExp(r'youtube\.com/pcs/activeview')},
    {'name': 'PubAds server', 'pattern': RegExp(r'\bpubads\b')},
    {'name': 'Pop-under/Pop-up ads redirection helper', 'pattern': RegExp(r'popunder|popup')},
  ];

  static AdBlockInterceptResult match(String url, {String? requestType, String? sourceUrl}) {
    final lowerUrl = url.toLowerCase();
    String sourceDomain = 'unknown';
    if (sourceUrl != null) {
      try {
        final uri = Uri.parse(sourceUrl);
        sourceDomain = uri.host.replaceAll('www.', '');
      } catch (_) {}
    } else {
      try {
        final uri = Uri.parse(url);
        sourceDomain = uri.host.replaceAll('www.', '');
      } catch (_) {}
    }

    for (final rule in _rules) {
      final pattern = rule['pattern'] as RegExp;
      if (pattern.hasMatch(lowerUrl)) {
        return AdBlockInterceptResult(
          isBlocked: true,
          matchedRule: rule['name'] as String,
          requestUrl: url,
          requestType: requestType,
          sourceDomain: sourceDomain,
        );
      }
    }

    return AdBlockInterceptResult(
      isBlocked: false,
      requestUrl: url,
      requestType: requestType,
      sourceDomain: sourceDomain,
    );
  }
}
