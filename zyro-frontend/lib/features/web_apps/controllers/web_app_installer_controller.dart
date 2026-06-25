import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/tab_model.dart';
import '../services/web_app_shortcut_channel.dart';

class InstalledWebApp {
  final String id;
  final String name;
  final String? shortName;
  final String domain;
  final String startUrl;
  final String? scope;
  final String? iconUrl;
  final List<String> iconUrls;
  final String? localIconPath;
  final String? themeColor;
  final String? backgroundColor;
  final String? displayMode;
  final String shortcutId;
  final DateTime installedAt;
  final DateTime? lastOpenedAt;

  const InstalledWebApp({
    required this.id,
    required this.name,
    this.shortName,
    required this.domain,
    required this.startUrl,
    this.scope,
    this.iconUrl,
    this.iconUrls = const [],
    this.localIconPath,
    this.themeColor,
    this.backgroundColor,
    this.displayMode,
    required this.shortcutId,
    required this.installedAt,
    this.lastOpenedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'domain': domain,
        'startUrl': startUrl,
        'scope': scope,
        'iconUrl': iconUrl,
        'localIconPath': localIconPath,
        'themeColor': themeColor,
        'backgroundColor': backgroundColor,
        'displayMode': displayMode,
        'shortcutId': shortcutId,
        'installedAt': installedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      };

  factory InstalledWebApp.fromMap(Map<String, dynamic> map) {
    final startUrl = map['startUrl'] as String? ?? '';
    return InstalledWebApp(
      id: map['id'] as String? ?? _webAppIdForUrl(startUrl),
      name: map['name'] as String? ?? _webAppDomainForUrl(startUrl),
      shortName: map['shortName'] as String?,
      domain: map['domain'] as String? ?? _webAppDomainForUrl(startUrl),
      startUrl: startUrl,
      scope: map['scope'] as String?,
      iconUrl: map['iconUrl'] as String?,
      localIconPath: map['localIconPath'] as String?,
      themeColor: map['themeColor'] as String?,
      backgroundColor: map['backgroundColor'] as String?,
      displayMode: map['displayMode'] as String?,
      shortcutId: map['shortcutId'] as String? ?? _webAppShortcutIdForUrl(startUrl),
      installedAt: DateTime.tryParse(map['installedAt'] as String? ?? '') ??
          DateTime.now(),
      lastOpenedAt: DateTime.tryParse(map['lastOpenedAt'] as String? ?? ''),
    );
  }
}

class WebAppInstallCandidate {
  final String name;
  final String? shortName;
  final String domain;
  final String startUrl;
  final String? scope;
  final String? iconUrl;
  final String? themeColor;
  final String? backgroundColor;
  final String? displayMode;

  const WebAppInstallCandidate({
    required this.name,
    this.shortName,
    required this.domain,
    required this.startUrl,
    this.scope,
    this.iconUrl,
    this.themeColor,
    this.backgroundColor,
    this.displayMode,
  });
}

class WebAppInstallResult {
  final InstalledWebApp? app;
  final bool duplicate;
  final bool shortcutSupported;
  final String? message;

  const WebAppInstallResult({
    this.app,
    this.duplicate = false,
    this.shortcutSupported = true,
    this.message,
  });
}

class WebAppInstallerController extends ChangeNotifier {
  static const _key = 'zyro_installed_web_apps';

  List<InstalledWebApp> _apps = [];

  List<InstalledWebApp> get apps => List.unmodifiable(_apps);

  WebAppInstallerController() {
    _load();
  }

  Future<WebAppInstallCandidate> detectCandidate(TabModel tab) async {
    final url = tab.url;
    final uri = Uri.tryParse(url);
    final domain = uri?.host.replaceFirst(RegExp(r'^www\.'), '') ?? url;
    if (kDebugMode) debugPrint('[WEB APPS] Web app detection started: $url');

    Map<String, dynamic> page = const {};
    try {
      final result = await tab.controller?.evaluateJavascript(source: '''
(function() {
  function attr(selector, name) {
    var el = document.querySelector(selector);
    return el ? el.getAttribute(name) : null;
  }
  function content(selector) {
    var el = document.querySelector(selector);
    return el ? el.getAttribute('content') : null;
  }
  var icons = Array.prototype.slice.call(document.querySelectorAll('link[rel~="apple-touch-icon"], link[rel~="apple-touch-icon-precomposed"], link[rel~="mask-icon"], link[rel~="icon"], link[rel="shortcut icon"]')).map(function(el) {
    return { href: el.href || el.getAttribute('href'), sizes: el.getAttribute('sizes') || '', rel: el.getAttribute('rel') || '' };
  });
  return JSON.stringify({
    manifestHref: attr('link[rel="manifest"]', 'href'),
    title: document.title || '',
    ogSiteName: content('meta[property="og:site_name"]'),
    applicationName: content('meta[name="application-name"]'),
    appleTitle: content('meta[name="apple-mobile-web-app-title"]'),
    themeColor: content('meta[name="theme-color"]'),
    icons: icons
  });
})()
''');
      if (result is String && result.isNotEmpty) {
        page = Map<String, dynamic>.from(jsonDecode(result));
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[WEB APPS] Page metadata detection failed: $error');
    }

    Map<String, dynamic> manifest = const {};
    final manifestHref = page['manifestHref'] as String?;
    if (manifestHref != null && manifestHref.isNotEmpty) {
      final manifestUrl = _resolveUrl(url, manifestHref);
      try {
        final response = await http.get(Uri.parse(manifestUrl));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          manifest = Map<String, dynamic>.from(jsonDecode(response.body));
          if (kDebugMode) debugPrint('[WEB APPS] Manifest parsed');
        }
      } catch (error) {
        if (kDebugMode) debugPrint('[WEB APPS] Manifest fetch failed: $error');
      }
    } else if (kDebugMode) {
      debugPrint('[WEB APPS] No manifest found, fallback install available');
    }

    final manifestName = _cleanName(manifest['name'] as String?);
    final manifestShortName = _cleanName(manifest['short_name'] as String?);
    final name = manifestName ??
        manifestShortName ??
        _cleanName(page['ogSiteName'] as String?) ??
        _cleanName(page['applicationName'] as String?) ??
        _cleanName(page['appleTitle'] as String?) ??
        _cleanName(page['title'] as String?) ??
        _titleCaseDomain(domain);
    if (kDebugMode) {
      debugPrint(manifestName != null
          ? '[WEB APPS] Manifest name found: $manifestName'
          : '[WEB APPS] Fallback name used: $name');
      debugPrint('[WEB APPS] Real app name detected: $name');
    }

    final startUrl = _resolveUrl(url, manifest['start_url'] as String? ?? url);
    final iconUrls = _bestIconUrls(url, manifest['icons'], page['icons']);
    final iconUrl = iconUrls.isEmpty ? null : iconUrls.first;
    if (kDebugMode) debugPrint('[WEB APPS] Best icon selected: ${iconUrl ?? 'fallback'}');

    return WebAppInstallCandidate(
      name: name,
      shortName: manifestShortName,
      domain: domain,
      startUrl: startUrl,
      scope: manifest['scope'] == null ? null : _resolveUrl(url, manifest['scope'] as String),
      iconUrl: iconUrl,
      iconUrls: iconUrls,
      themeColor: manifest['theme_color'] as String? ?? page['themeColor'] as String?,
      backgroundColor: manifest['background_color'] as String?,
      displayMode: manifest['display'] as String?,
    );
  }

  bool installed(String url) => _apps.any((app) => _sameInstallTarget(app.startUrl, url));

  InstalledWebApp? appForUrl(String url) {
    try {
      return _apps.firstWhere((app) => _sameInstallTarget(app.startUrl, url));
    } catch (_) {
      return null;
    }
  }

  Future<WebAppInstallResult> installCandidate(WebAppInstallCandidate candidate) async {
    if (installed(candidate.startUrl)) {
      if (kDebugMode) debugPrint('[WEB APPS] Duplicate install blocked');
      return const WebAppInstallResult(duplicate: true);
    }

    final localIconPath = await _cacheIcon(candidate);
    final app = InstalledWebApp(
      id: _webAppIdForUrl(candidate.startUrl),
      name: candidate.name,
      shortName: candidate.shortName,
      domain: candidate.domain,
      startUrl: candidate.startUrl,
      scope: candidate.scope,
      iconUrl: candidate.iconUrl,
      localIconPath: localIconPath,
      themeColor: candidate.themeColor,
      backgroundColor: candidate.backgroundColor,
      displayMode: candidate.displayMode,
      shortcutId: _webAppShortcutIdForUrl(candidate.startUrl),
      installedAt: DateTime.now(),
    );

    _apps.add(app);
    await _save();
    notifyListeners();
    if (kDebugMode) debugPrint('[WEB APPS] Web app saved');

    final shortcut = await WebAppShortcutChannel.pinWebAppShortcut(
      id: app.shortcutId,
      name: app.name,
      url: app.startUrl,
      iconPath: app.localIconPath,
    );
    final supported = shortcut['supported'] != false;
    if (kDebugMode) {
      debugPrint('[WEB APPS] Shortcut pin supported=$supported');
      debugPrint('[WEB APPS] Shortcut pin requested');
    }

    return WebAppInstallResult(
      app: app,
      shortcutSupported: supported,
      message: shortcut['message'] as String?,
    );
  }

  Future<void> markOpened(String url) async {
    final index = _apps.indexWhere((app) => _sameInstallTarget(app.startUrl, url));
    if (index == -1) return;
    final app = _apps[index];
    _apps[index] = InstalledWebApp(
      id: app.id,
      name: app.name,
      shortName: app.shortName,
      domain: app.domain,
      startUrl: app.startUrl,
      scope: app.scope,
      iconUrl: app.iconUrl,
      localIconPath: app.localIconPath,
      themeColor: app.themeColor,
      backgroundColor: app.backgroundColor,
      displayMode: app.displayMode,
      shortcutId: app.shortcutId,
      installedAt: app.installedAt,
      lastOpenedAt: DateTime.now(),
    );
    await _save();
    notifyListeners();
  }

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw != null) {
      _apps = (jsonDecode(raw) as List)
          .map((item) => InstalledWebApp.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await (await SharedPreferences.getInstance())
        .setString(_key, jsonEncode(_apps.map((app) => app.toMap()).toList()));
  }

  Future<String?> _cacheIcon(WebAppInstallCandidate candidate) async {
    final iconUrls = candidate.iconUrls.isNotEmpty
        ? candidate.iconUrls
        : [
            if (candidate.iconUrl != null) candidate.iconUrl!,
          ];
    if (iconUrls.isEmpty) return null;
    try {
      final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'web_app_icons'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File(p.join(dir.path, '${_webAppIdForUrl(candidate.startUrl)}.png'));

      for (final iconUrl in iconUrls) {
        if (_looksLikeSvg(iconUrl)) {
          if (kDebugMode) debugPrint('[WEB APPS] Icon skipped unsupported SVG: $iconUrl');
          continue;
        }
        if (kDebugMode) debugPrint('[WEB APPS] Icon download started: $iconUrl');
        final response = await http.get(Uri.parse(iconUrl));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (kDebugMode) debugPrint('[WEB APPS] Icon download failed ${response.statusCode}: $iconUrl');
          continue;
        }
        final contentType = response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('svg')) {
          if (kDebugMode) debugPrint('[WEB APPS] Icon skipped SVG content: $iconUrl');
          continue;
        }
        final decoded = img.decodeImage(response.bodyBytes);
        if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
          if (kDebugMode) debugPrint('[WEB APPS] Icon decode failed: $iconUrl');
          continue;
        }
        if (_isBlankImage(decoded)) {
          if (kDebugMode) debugPrint('[WEB APPS] Icon rejected as blank/transparent: $iconUrl');
          continue;
        }
        if (kDebugMode) {
          debugPrint('[WEB APPS] Decoded icon size: ${decoded.width}x${decoded.height}');
        }
        final square = _makeLauncherIcon(decoded);
        await file.writeAsBytes(Uint8List.fromList(img.encodePng(square)), flush: true);
        if (kDebugMode) {
          debugPrint('[WEB APPS] Icon cached: ${file.path}');
          debugPrint('[WEB APPS] Shortcut will use real icon');
        }
        return file.path;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('[WEB APPS] Icon cache failed: $error');
    }
    if (kDebugMode) debugPrint('[WEB APPS] Fallback icon used');
    return null;
  }

  static bool _sameInstallTarget(String a, String b) {
    final aUri = Uri.tryParse(a);
    final bUri = Uri.tryParse(b);
    if (aUri == null || bUri == null) return a == b;
    return aUri.scheme == bUri.scheme &&
        aUri.host == bUri.host &&
        (aUri.path.isEmpty ? '/' : aUri.path) == (bUri.path.isEmpty ? '/' : bUri.path);
  }

  static String _resolveUrl(String base, String value) {
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return parsed.toString();
    return Uri.parse(base).resolve(value).toString();
  }

  static List<String> _bestIconUrls(String baseUrl, dynamic manifestIcons, dynamic pageIcons) {
    final candidates = <Map<String, dynamic>>[];
    if (manifestIcons is List) {
      for (final icon in manifestIcons) {
        if (icon is Map && icon['src'] != null) {
          final src = icon['src'].toString().trim();
          if (src.isEmpty || _looksLikeSvg(src)) continue;
          candidates.add({
            'href': src,
            'sizes': icon['sizes']?.toString() ?? '',
            'priority': 0,
          });
        }
      }
    }
    if (pageIcons is List) {
      for (final icon in pageIcons) {
        if (icon is Map && icon['href'] != null) {
          final rel = icon['rel']?.toString().toLowerCase() ?? '';
          final href = icon['href'].toString().trim();
          if (href.isEmpty || _looksLikeSvg(href)) continue;
          candidates.add({
            'href': href,
            'sizes': icon['sizes']?.toString() ?? '',
            'priority': rel.contains('apple-touch-icon')
                ? 1
                : rel.contains('mask-icon')
                    ? 2
                    : rel.contains('shortcut')
                        ? 4
                        : 3,
          });
        }
      }
    }
    candidates.sort((a, b) {
      final priority = (a['priority'] as int).compareTo(b['priority'] as int);
      if (priority != 0) return priority;
      final aScore = _iconScore(a['href'] as String, a['sizes'] as String);
      final bScore = _iconScore(b['href'] as String, b['sizes'] as String);
      return bScore.compareTo(aScore);
    });
    final urls = <String>[];
    for (final candidate in candidates) {
      final resolved = _resolveUrl(baseUrl, candidate['href'] as String);
      if (!urls.contains(resolved)) urls.add(resolved);
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri != null) {
      for (final fallback in [
        '/apple-touch-icon.png',
        '/favicon-512x512.png',
        '/favicon-192x192.png',
        '/favicon.ico',
      ]) {
        final resolved = uri.resolve(fallback).toString();
        if (!urls.contains(resolved)) urls.add(resolved);
      }
    }
    return urls;
  }

  static int _largestIconSize(String sizes) {
    final matches = RegExp(r'(\d+)x(\d+)').allMatches(sizes);
    if (matches.isEmpty) return 0;
    return matches.map((m) => int.tryParse(m.group(1) ?? '') ?? 0).fold(0, max);
  }

  static int _iconScore(String href, String sizes) {
    final size = _largestIconSize(sizes);
    final lower = href.toLowerCase();
    var score = size;
    if (size >= 512) score += 5000;
    if (size >= 192) score += 3000;
    if (lower.endsWith('.png')) score += 400;
    if (lower.endsWith('.webp')) score += 350;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) score += 300;
    if (lower.endsWith('.ico')) score -= 500;
    if (lower.contains('512')) score += 250;
    if (lower.contains('192')) score += 200;
    return score;
  }

  static bool _looksLikeSvg(String url) => url.toLowerCase().split('?').first.endsWith('.svg');

  static bool _isBlankImage(img.Image image) {
    final sampleStepX = max(1, image.width ~/ 24);
    final sampleStepY = max(1, image.height ~/ 24);
    var visible = 0;
    var varied = 0;
    int? first;
    for (var y = 0; y < image.height; y += sampleStepY) {
      for (var x = 0; x < image.width; x += sampleStepX) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.a.toInt();
        if (alpha > 12) visible++;
        final argb = (alpha << 24) |
            (pixel.r.toInt() << 16) |
            (pixel.g.toInt() << 8) |
            pixel.b.toInt();
        first ??= argb;
        if (argb != first) varied++;
      }
    }
    return visible < 6 || varied < 2;
  }

  static img.Image _makeLauncherIcon(img.Image source) {
    final cropSize = min(source.width, source.height);
    final cropped = img.copyCrop(
      source,
      x: ((source.width - cropSize) / 2).round(),
      y: ((source.height - cropSize) / 2).round(),
      width: cropSize,
      height: cropSize,
    );
    final resized = img.copyResize(cropped, width: 168, height: 168, interpolation: img.Interpolation.cubic);
    final output = img.Image(width: 192, height: 192, numChannels: 4);
    img.fill(output, color: img.ColorRgba8(255, 255, 255, 255));
    img.compositeImage(output, resized, dstX: 12, dstY: 12);
    return output;
  }

  static String? _cleanName(String? raw) {
    if (raw == null) return null;
    var value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return null;
    final known = RegExp(
      r'\s+[-|\u2013\u2014]\s+(Google|YouTube|Official Site)$',
      caseSensitive: false,
    );
    value = value.replaceFirst(known, '');
    final separators = [' | ', ' - ', ' \u2013 ', ' \u2014 ', ': '];
    for (final separator in separators) {
      if (value.contains(separator)) {
        final first = value.split(separator).first.trim();
        if (first.length >= 3 && first.length <= 28) {
          value = first;
          break;
        }
      }
    }
    return value.length > 40 ? value.substring(0, 40).trim() : value;
  }

  static String _domainForUrl(String url) {
    return _webAppDomainForUrl(url);
  }

  static String _titleCaseDomain(String domain) {
    final root = domain.split('.').first;
    if (root.isEmpty) return domain;
    return root[0].toUpperCase() + root.substring(1);
  }

  static String _idForUrl(String url) => _webAppIdForUrl(url);

  static String _shortcutIdForUrl(String url) => _webAppShortcutIdForUrl(url);
}

String _webAppDomainForUrl(String url) {
  return Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? url;
}

String _webAppIdForUrl(String url) {
  return _webAppShortcutIdForUrl(url).replaceFirst('zyro_webapp_', '');
}

String _webAppShortcutIdForUrl(String url) {
  final uri = Uri.tryParse(url);
  final raw = '${uri?.host ?? url}_${uri?.path ?? ''}';
  return 'zyro_webapp_${raw.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').toLowerCase()}';
}
