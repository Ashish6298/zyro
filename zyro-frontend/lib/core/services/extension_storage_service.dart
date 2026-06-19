import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extension_model.dart';

class ExtensionStorageService {
  static const String _storageKey = 'zyro_extensions_states';

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

  static Future<void> saveExtensionStates(List<ExtensionModel> extensions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = extensions.map((e) => e.toMap()).toList();
    final jsonStr = json.encode(data);
    await prefs.setString(_storageKey, jsonStr);
  }
}
