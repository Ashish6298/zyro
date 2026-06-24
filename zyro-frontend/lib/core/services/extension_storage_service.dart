import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extension_model.dart';

class ExtensionStorageService {
  static const String _storageKey = 'zyro_extensions_states';
  static const String _floatingVideosId = 'floating_videos';

  static Future<void> removeFloatingVideosState() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((key) {
      final normalized = key.toLowerCase();
      return normalized.contains('floating_videos') ||
          normalized.contains('floating_video') ||
          normalized.contains('zyro_floating_video');
    }).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return;
    try {
      final List<dynamic> entries = json.decode(jsonStr);
      final cleanedEntries = entries.where((entry) {
        return entry is! Map || entry['id'] != _floatingVideosId;
      }).toList();
      if (cleanedEntries.length != entries.length) {
        await prefs.setString(_storageKey, json.encode(cleanedEntries));
      }
    } catch (_) {
      // Preserve unrelated extension storage if a legacy value cannot be parsed.
    }
  }

  static Future<List<Map<String, dynamic>>> loadExtensionStates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      print("[EXTENSION STORAGE ERROR] Failed to load extension states: $e");
      return [];
    }
  }

  static Future<void> saveExtensionStates(
    List<ExtensionModel> extensions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = extensions.map((e) => e.toMap()).toList();
    final jsonStr = json.encode(data);
    await prefs.setString(_storageKey, jsonStr);
  }
}
