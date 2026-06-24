import 'package:flutter/foundation.dart';
import '../models/permission_enums.dart';
import '../models/website_permission_rule.dart';
import '../services/website_permission_storage_service.dart';

class WebsitePermissionsController extends ChangeNotifier {
  WebsitePermissionsController({WebsitePermissionStorageService? storage})
    : _storage = storage ?? WebsitePermissionStorageService();

  final WebsitePermissionStorageService _storage;
  List<WebsitePermissionRule> _rules = [];
  bool _loaded = false;

  List<WebsitePermissionRule> get rules => List.unmodifiable(_rules);
  bool get loaded => _loaded;

  Future<void> load() async {
    _rules = await _storage.load();
    _loaded = true;
    notifyListeners();
  }

  WebsitePermissionRule? ruleFor(String domain, PermissionType type) {
    for (final rule in _rules) {
      if (rule.domain == domain && rule.permissionType == type) return rule;
    }
    return null;
  }

  int countFor(PermissionType type) =>
      _rules.where((rule) => rule.permissionType == type).length;

  List<WebsitePermissionRule> rulesFor(PermissionType type) =>
      _rules.where((rule) => rule.permissionType == type).toList()
        ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));

  Future<void> upsert(WebsitePermissionRule rule) async {
    _rules.removeWhere((item) => item.id == rule.id);
    _rules.add(rule);
    await _storage.save(_rules);
    if (kDebugMode)
      debugPrint(
        '[WEBSITE PERMISSIONS] rule saved: ${rule.domain} ${rule.permissionType.name} ${rule.status.name}',
      );
    notifyListeners();
  }

  Future<void> clear() async {
    _rules = [];
    await _storage.clear();
    if (kDebugMode) debugPrint('[WEBSITE PERMISSIONS] rules cleared');
    notifyListeners();
  }
}
