import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/usage_entry.dart';

class UsageStorageService {
  static const String _storageKey = 'zyro_usage_analytics_entries';

  Future<List<UsageEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((entry) => UsageEntry.fromMap(Map<String, dynamic>.from(entry)))
          .where((entry) => entry.domain.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntries(List<UsageEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final data = entries.map((entry) => entry.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(data));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
