import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ad_block_stats_model.dart';

class AdBlockStatsService extends ChangeNotifier {
  static const String _storageKey = 'zyro_adblock_stats';
  
  AdBlockStatsModel _stats = AdBlockStatsModel.empty();
  bool _isLoaded = false;

  AdBlockStatsModel get stats => _stats;

  AdBlockStatsService() {
    _init();
  }

  Future<void> _init() async {
    await loadStats();
  }

  Future<void> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        _stats = AdBlockStatsModel.fromJson(jsonStr);
        _checkDayReset();
      } else {
        _stats = AdBlockStatsModel.empty();
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print("[ADBLOCK STATS SERVICE ERROR] Failed to load stats: $e");
    }
  }

  Future<void> saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _stats.toJson());
    } catch (e) {
      print("[ADBLOCK STATS SERVICE ERROR] Failed to save stats: $e");
    }
  }

  void _checkDayReset() {
    final todayStr = _getTodayString();
    if (_stats.lastUpdatedDate != todayStr) {
      _stats = _stats.copyWith(
        todayBlocked: 0,
        lastUpdatedDate: todayStr,
      );
    }
  }

  Future<void> recordBlockedEvent(String url) async {
    if (!_isLoaded) await loadStats();
    
    _checkDayReset();
    
    String domain = 'other';
    try {
      final uri = Uri.parse(url);
      domain = uri.host.replaceAll('www.', '');
      if (domain.isEmpty) {
        domain = 'other';
      }
    } catch (_) {
      // Fallback if parsing fails (e.g. malformed url)
      final hostMatch = RegExp(r'https?://([^/]+)').firstMatch(url);
      if (hostMatch != null && hostMatch.groupCount >= 1) {
        domain = hostMatch.group(1)!.replaceAll('www.', '');
      }
    }

    final newDomainCounts = Map<String, int>.from(_stats.domainBlockedCounts);
    newDomainCounts[domain] = (newDomainCounts[domain] ?? 0) + 1;

    _stats = _stats.copyWith(
      totalBlocked: _stats.totalBlocked + 1,
      todayBlocked: _stats.todayBlocked + 1,
      domainBlockedCounts: newDomainCounts,
    );

    notifyListeners();
    // Async save to avoid blocking execution
    saveStats();
  }

  Future<void> clearStats() async {
    _stats = AdBlockStatsModel.empty();
    notifyListeners();
    await saveStats();
  }

  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}
