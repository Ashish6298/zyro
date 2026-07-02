import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/website_vault_domain_summary.dart';
import '../models/website_vault_item.dart';
import '../models/website_vault_type.dart';
import '../services/website_vault_domain_service.dart';
import '../services/website_vault_file_service.dart';
import '../services/website_vault_storage_service.dart';

enum WebsiteVaultSortMode { recentlyUpdated, mostItems }

class WebsiteVaultController extends ChangeNotifier {
  WebsiteVaultController({
    WebsiteVaultStorageService? storageService,
    WebsiteVaultFileService? fileService,
    WebsiteVaultDomainService? domainService,
  }) : _storageService = storageService ?? WebsiteVaultStorageService(),
       _fileService = fileService ?? const WebsiteVaultFileService(),
       _domainService = domainService ?? const WebsiteVaultDomainService() {
    load();
  }

  final WebsiteVaultStorageService _storageService;
  final WebsiteVaultFileService _fileService;
  final WebsiteVaultDomainService _domainService;
  final _uuid = const Uuid();

  List<WebsiteVaultItem> _items = [];
  bool _loading = true;
  String _searchQuery = '';
  WebsiteVaultSortMode _sortMode = WebsiteVaultSortMode.recentlyUpdated;

  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  WebsiteVaultSortMode get sortMode => _sortMode;
  List<WebsiteVaultItem> get items => List.unmodifiable(_items);

  List<WebsiteVaultDomainSummary> get domainSummaries {
    final filtered = _filterItems(_items, _searchQuery);
    final grouped = <String, List<WebsiteVaultItem>>{};
    for (final item in filtered) {
      grouped.putIfAbsent(item.domain, () => []).add(item);
    }
    final summaries = grouped.entries.map((entry) {
      final items = entry.value;
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final typeCounts = <WebsiteVaultType, int>{};
      var totalStorage = 0;
      for (final item in items) {
        typeCounts[item.type] = (typeCounts[item.type] ?? 0) + 1;
        totalStorage += item.fileSize ?? 0;
      }
      return WebsiteVaultDomainSummary(
        domain: entry.key,
        faviconUrl: _domainService.faviconUrl(entry.key),
        itemCount: items.length,
        latestItemAt: items.first.updatedAt,
        typeCounts: typeCounts,
        totalStorageBytes: totalStorage,
      );
    }).toList();

    if (_sortMode == WebsiteVaultSortMode.mostItems) {
      summaries.sort((a, b) {
        final count = b.itemCount.compareTo(a.itemCount);
        return count != 0 ? count : b.latestItemAt.compareTo(a.latestItemAt);
      });
    } else {
      summaries.sort((a, b) => b.latestItemAt.compareTo(a.latestItemAt));
    }
    return summaries;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _storageService.loadItems();
    _loading = false;
    if (kDebugMode) {
      debugPrint(
        '[WEBSITE VAULT] Domain summaries loaded: ${domainSummaries.length}',
      );
    }
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Vault search performed');
    notifyListeners();
  }

  void setSortMode(WebsiteVaultSortMode value) {
    _sortMode = value;
    notifyListeners();
  }

  List<WebsiteVaultItem> itemsForDomain(
    String domain, {
    String query = '',
    WebsiteVaultType? type,
  }) {
    final normalizedQuery = query.trim();
    final filtered =
        _filterItems(
            _items.where((item) => item.domain == domain).toList(),
            normalizedQuery,
          ).where((item) => type == null || item.type == type).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  Future<WebsiteVaultItem?> saveCurrentPage({
    required String url,
    required String title,
    WebsiteVaultType type = WebsiteVaultType.page,
    String? noteText,
    List<String> tags = const [],
  }) async {
    final domain = _domainService.normalize(url);
    if (domain == null) return null;
    final item = WebsiteVaultItem(
      id: _uuid.v4(),
      domain: domain,
      origin: 'current_page',
      sourceUrl: url,
      title: title.trim().isEmpty ? domain : title.trim(),
      type: type,
      noteText: noteText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
    );
    await _add(item);
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Current page saved to vault');
    return item;
  }

  Future<WebsiteVaultItem?> addManualItem({
    required String domainOrUrl,
    required String title,
    required WebsiteVaultType type,
    String sourceUrl = '',
    String? noteText,
    List<String> tags = const [],
  }) async {
    final domain = _domainService.normalize(
      sourceUrl.trim().isNotEmpty ? sourceUrl : domainOrUrl,
    );
    if (domain == null) return null;
    final item = WebsiteVaultItem(
      id: _uuid.v4(),
      domain: domain,
      origin: 'manual',
      sourceUrl: sourceUrl,
      title: title.trim().isEmpty ? domain : title.trim(),
      type: type,
      noteText: noteText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
    );
    await _add(item);
    return item;
  }

  Future<WebsiteVaultItem?> linkScreenshot({
    required String title,
    required String sourceUrl,
    required String filePath,
    required String mimeType,
    required int fileSize,
    required String captureType,
  }) async {
    final domain = _domainService.normalize(sourceUrl);
    if (domain == null || filePath.isEmpty) return null;
    final item = WebsiteVaultItem(
      id: _uuid.v4(),
      domain: domain,
      origin: 'screenshot_pro',
      sourceUrl: sourceUrl,
      title: title.trim().isEmpty ? 'Screenshot' : title.trim(),
      type: captureType == 'pdf'
          ? WebsiteVaultType.pdf
          : WebsiteVaultType.screenshot,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      thumbnailPath: mimeType.startsWith('image/') ? filePath : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: const ['Screenshot Pro'],
    );
    await _add(item);
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Screenshot linked to vault');
    return item;
  }

  Future<WebsiteVaultItem?> linkDownload({
    required String title,
    required String sourceUrl,
    required String? filePath,
    String? mimeType,
    int? fileSize,
  }) async {
    final domain = _domainService.normalize(sourceUrl);
    if (domain == null) return null;
    final resolvedSize = fileSize ?? await _fileService.sizeForPath(filePath);
    final item = WebsiteVaultItem(
      id: _uuid.v4(),
      domain: domain,
      origin: 'download',
      sourceUrl: sourceUrl,
      title: title.trim().isEmpty ? 'Downloaded file' : title.trim(),
      type: WebsiteVaultType.download,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: resolvedSize,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: const ['Download'],
    );
    await _add(item);
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Download linked to vault');
    return item;
  }

  Future<void> renameItem(String id, String title) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1 || title.trim().isEmpty) return;
    _items[index] = _items[index].copyWith(
      title: title.trim(),
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> deleteItem(String id, {bool deleteLocalFile = false}) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = _items.removeAt(index);
    if (deleteLocalFile) {
      await _fileService.deleteLocalFile(item.filePath);
    }
    await _persist();
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Vault item deleted');
  }

  Future<void> clearDomain(String domain) async {
    _items.removeWhere((item) => item.domain == domain);
    await _persist();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _storageService.clear();
    notifyListeners();
  }

  Future<void> _add(WebsiteVaultItem item) async {
    _items.insert(0, item);
    await _persist();
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Vault item created');
  }

  Future<void> _persist() async {
    await _storageService.saveItems(_items);
    notifyListeners();
  }

  List<WebsiteVaultItem> _filterItems(
    List<WebsiteVaultItem> input,
    String query,
  ) {
    final lower = query.toLowerCase();
    if (lower.isEmpty) return input;
    return input.where((item) {
      return item.domain.toLowerCase().contains(lower) ||
          item.title.toLowerCase().contains(lower) ||
          item.sourceUrl.toLowerCase().contains(lower) ||
          (item.noteText ?? '').toLowerCase().contains(lower) ||
          item.tags.any((tag) => tag.toLowerCase().contains(lower));
    }).toList();
  }
}
