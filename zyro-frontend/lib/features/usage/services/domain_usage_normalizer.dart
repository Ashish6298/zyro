import 'package:flutter/foundation.dart';

class DomainUsageNormalizer {
  const DomainUsageNormalizer._();

  static const Set<String> _ignoredHosts = {
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
  };

  static String? normalize(String? rawUrlOrHost) {
    final raw = rawUrlOrHost?.trim();
    if (raw == null || raw.isEmpty) return null;

    Uri? uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (!uri.hasScheme && raw.contains('.')) {
      uri = Uri.tryParse('https://$raw');
    }
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme.isNotEmpty &&
        uri.scheme != 'http' &&
        uri.scheme != 'https') {
      debugPrint('Usage tracking skipped for internal URL');
      return null;
    }

    final host = uri.host.toLowerCase();
    if (_ignoredHosts.contains(host) ||
        host.endsWith('.local') ||
        host.startsWith('file.')) {
      debugPrint('Usage tracking skipped for internal URL');
      return null;
    }

    final labels = host
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'^m\.'), '')
        .split('.')
        .where((part) => part.isNotEmpty)
        .toList();
    if (labels.length <= 2) {
      final domain = labels.join('.');
      debugPrint('Domain normalized');
      return domain;
    }

    final lastTwo = labels.sublist(labels.length - 2).join('.');
    final lastThree = labels.sublist(labels.length - 3).join('.');
    const secondLevelSuffixes = {'co.uk', 'com.au', 'co.in', 'com.br', 'co.jp'};
    final domain = secondLevelSuffixes.contains(lastTwo) ? lastThree : lastTwo;
    debugPrint('Domain normalized');
    return domain;
  }
}
