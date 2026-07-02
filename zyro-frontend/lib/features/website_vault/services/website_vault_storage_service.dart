import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/website_vault_item.dart';

class WebsiteVaultStorageService {
  static const String _storageKey = 'zyro_website_vault_items';

  Future<List<WebsiteVaultItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map(
            (item) => WebsiteVaultItem.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.id.isNotEmpty && item.domain.isNotEmpty)
          .toList();
    } catch (error) {
      if (kDebugMode) debugPrint('[WEBSITE VAULT] Vault storage error: $error');
      return [];
    }
  }

  Future<void> saveItems(List<WebsiteVaultItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(items.map((item) => item.toMap()).toList()),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[WEBSITE VAULT] Vault storage error: $error');
      rethrow;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
