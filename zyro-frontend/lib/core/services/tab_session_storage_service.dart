import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tab_model.dart';

class TabSessionStorageService {
  static const String _sessionKey = 'zyro_tab_session_states';

  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionKey);
    if (jsonStr == null) return null;
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print("[TAB SESSION STORAGE ERROR] Failed to decode tab session: $e");
      return null;
    }
  }

  static Future<void> saveSession({
    required List<TabModel> standaloneTabs,
    required List<TabGroup> groups,
    required int currentIndex,
  }) async {
    // Only save normal (non-incognito) tabs
    final nonIncognitoStandalone = standaloneTabs.where((t) => !t.isIncognito).toList();
    
    final List<Map<String, dynamic>> groupsData = [];
    for (var group in groups) {
      final groupTabs = group.tabs.where((t) => !t.isIncognito).toList();
      if (groupTabs.isNotEmpty) {
        groupsData.add({
          'id': group.id,
          'name': group.name,
          'color': group.color.value,
          'createdAt': group.createdAt.toIso8601String(),
          'tabs': groupTabs.map((t) => _tabToMap(t)).toList(),
        });
      }
    }

    final data = {
      'standaloneTabs': nonIncognitoStandalone.map((t) => _tabToMap(t)).toList(),
      'groups': groupsData,
      'currentIndex': currentIndex,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, json.encode(data));
    print("[TAB SESSION STORAGE] Session successfully persisted to SharedPreferences.");
  }

  static Map<String, dynamic> _tabToMap(TabModel tab) {
    return {
      'id': tab.id,
      'url': tab.url,
      'title': tab.title,
      'faviconUrl': tab.favicon?.url.toString(),
      'isDesktopMode': tab.isDesktopMode,
      'lastVisitedAt': tab.lastVisitedAt?.toIso8601String(),
      'createdAt': tab.createdAt?.toIso8601String(),
      'updatedAt': tab.updatedAt?.toIso8601String(),
      'isActive': tab.isActive,
      'canGoBack': tab.canGoBack,
      'canGoForward': tab.canGoForward,
      'scrollX': tab.scrollX,
      'scrollY': tab.scrollY,
      'groupId': tab.groupId,
      'groupName': tab.groupName,
      'groupColor': tab.groupColor?.value,
      'groupCreatedAt': tab.groupCreatedAt?.toIso8601String(),
      'groupTabCount': tab.groupTabCount,
    };
  }
}
