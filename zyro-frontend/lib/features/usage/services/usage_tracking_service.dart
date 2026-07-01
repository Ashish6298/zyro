import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/usage_entry.dart';
import '../services/domain_usage_normalizer.dart';
import 'usage_storage_service.dart';

class UsageTrackingService extends ChangeNotifier {
  UsageTrackingService({UsageStorageService? storage})
    : _storage = storage ?? UsageStorageService() {
    _loadFuture = load();
  }

  final UsageStorageService _storage;
  final Map<String, UsageEntry> _entries = {};
  final Set<String> _recentRequestKeys = {};
  Timer? _saveDebounce;
  late final Future<void> _loadFuture;
  bool _loaded = false;

  bool get loaded => _loaded;

  List<UsageEntry> get entries {
    final now = DateTime.now();
    return _entries.values.map((entry) => entry.rolledTo(now)).toList()
      ..sort((a, b) => b.monthlyBytes.compareTo(a.monthlyBytes));
  }

  int get todayBytes => entries.fold(0, (sum, entry) => sum + entry.todayBytes);
  int get monthlyBytes =>
      entries.fold(0, (sum, entry) => sum + entry.monthlyBytes);
  int get totalBytes => entries.fold(0, (sum, entry) => sum + entry.totalBytes);

  Future<void> load() async {
    final loadedEntries = await _storage.loadEntries();
    _entries
      ..clear()
      ..addEntries(
        loadedEntries.map(
          (entry) => MapEntry(entry.domain, entry.rolledTo(DateTime.now())),
        ),
      );
    _loaded = true;
    debugPrint('Monthly usage loaded');
    notifyListeners();
  }

  void observeRequest({
    required String url,
    required String sourceUrl,
    bool isMainFrame = false,
    String? requestType,
    int? contentLength,
  }) {
    if (!_loaded) {
      unawaited(
        _loadFuture.then(
          (_) => observeRequest(
            url: url,
            sourceUrl: sourceUrl,
            isMainFrame: isMainFrame,
            requestType: requestType,
            contentLength: contentLength,
          ),
        ),
      );
      return;
    }

    debugPrint('Usage request observed');
    final domain = DomainUsageNormalizer.normalize(url);
    if (domain == null) return;

    DomainUsageNormalizer.normalize(sourceUrl);
    final category = _categoryFor(url, requestType, isMainFrame);
    final bytes = contentLength ?? _estimateBytes(url, category, isMainFrame);
    if (contentLength != null) {
      debugPrint('Content length detected');
    }

    final key = _requestKey(url, bytes);
    if (!_recentRequestKeys.add(key)) return;
    if (_recentRequestKeys.length > 500) {
      _recentRequestKeys.remove(_recentRequestKeys.first);
    }

    final now = DateTime.now();
    final current = _entries[domain] ?? UsageEntry.empty(domain, now);
    final updated = current.record(
      bytes: bytes,
      now: now,
      category: category,
      faviconUrl: 'https://www.google.com/s2/favicons?sz=64&domain=$domain',
    );
    _entries[domain] = updated;
    debugPrint('Usage bytes recorded');
    debugPrint('Usage entry updated');
    _scheduleSave();
    notifyListeners();
  }

  Future<void> clear() async {
    _entries.clear();
    _recentRequestKeys.clear();
    _saveDebounce?.cancel();
    await _storage.clear();
    debugPrint('Usage data cleared');
    notifyListeners();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_storage.saveEntries(_entries.values.toList()));
    });
  }

  String _requestKey(String url, int bytes) {
    final minuteBucket = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    return '$url|$bytes|$minuteBucket';
  }

  String _categoryFor(String url, String? requestType, bool isMainFrame) {
    if (isMainFrame) return 'document';
    final lower = url.toLowerCase();
    if (RegExp(r'\.(mp4|webm|m3u8|m4s|mp3|aac|ogg)(\?|$)').hasMatch(lower)) {
      return 'media';
    }
    if (RegExp(r'\.(png|jpg|jpeg|gif|webp|svg|ico)(\?|$)').hasMatch(lower)) {
      return 'image';
    }
    if (RegExp(r'\.(js|css)(\?|$)').hasMatch(lower)) return 'asset';
    if (requestType != null &&
        requestType.isNotEmpty &&
        requestType != 'subresource') {
      return requestType;
    }
    return 'other';
  }

  int _estimateBytes(String url, String category, bool isMainFrame) {
    return switch (category) {
      'document' => 360 * 1024,
      'media' => 1536 * 1024,
      'image' => 180 * 1024,
      'asset' => 96 * 1024,
      _ when isMainFrame => 360 * 1024,
      _ => 40 * 1024,
    };
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
