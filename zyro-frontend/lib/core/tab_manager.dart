import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';
import 'models/tab_model.dart';
import 'globals.dart';

class TabManager extends ChangeNotifier {
  final List<TabModel> _standaloneTabs = [];
  final List<TabGroup> _groups = [];
  int _currentIndex = -1;
  bool _isFindingInPage = false;
  bool _isGlobalIncognito = false;
  final _uuid = const Uuid();

  List<TabModel> get tabs {
    final List<TabModel> allTabs = [];
    allTabs.addAll(_standaloneTabs);
    for (var group in _groups) {
      allTabs.addAll(group.tabs);
    }
    return allTabs;
  }

  List<TabGroup> get groups => _groups;

  int get currentIndex => _currentIndex;
  bool get isFindingInPage => _isFindingInPage;
  bool get isGlobalIncognito => _isGlobalIncognito;
  
  TabModel? get currentTab {
    final allTabs = tabs;
    return _currentIndex != -1 && _currentIndex < allTabs.length ? allTabs[_currentIndex] : null;
  }

  void setGlobalIncognito(bool value) {
    if (_isGlobalIncognito == value) return;
    _isGlobalIncognito = value;
    
    if (!_isGlobalIncognito) {
      // Clear all temporary data
      try {
        CookieManager.instance().deleteAllCookies();
        // Clear caches of all tabs
        for (var tab in tabs) {
          if (tab.isIncognito) {
            tab.controller?.clearCache();
            tab.controller?.evaluateJavascript(source: "window.localStorage.clear(); window.sessionStorage.clear();");
          }
        }
        print("[INCOGNITO DEBUG] Cleaned all incognito browser cookies, caches, and storage.");
      } catch (e) {
        print("[INCOGNITO ERROR] Error cleaning incognito mode data: $e");
      }
      
      // Close all incognito tabs
      final allTabs = List<TabModel>.from(tabs);
      for (var tab in allTabs) {
        if (tab.isIncognito) {
          if (tab.groupId != null) {
            final groupIndex = _groups.indexWhere((g) => g.id == tab.groupId);
            if (groupIndex != -1) {
              _groups[groupIndex].tabs.remove(tab);
              if (_groups[groupIndex].tabs.isEmpty) {
                _groups.removeAt(groupIndex);
              }
            }
          } else {
            _standaloneTabs.remove(tab);
          }
        }
      }
      
      // If no normal tabs are left, create one
      if (_standaloneTabs.isEmpty) {
        addNewTab();
      } else {
        _currentIndex = 0;
      }

      // Show Exit Incognito Mode Notification
      try {
        globalScaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incognito Mode Ended',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Private browsing has ended. Temporary cookies, cache, and site data have been wiped.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.indigo.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Got it',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } catch (e) {
        print("Error showing Incognito exit snackbar: $e");
      }
    } else {
      // Switching to Incognito mode:
      // Open a new blank incognito tab as the active one
      addNewTab(url: 'https://www.google.com', isIncognito: true);
    }
    notifyListeners();
  }

  TabModel addNewTab({String? url, bool isIncognito = false}) {
    final newTab = TabModel(
      id: _uuid.v4(),
      url: url ?? 'https://www.google.com',
      isIncognito: isIncognito || _isGlobalIncognito,
    );
    _standaloneTabs.add(newTab);
    _currentIndex = tabs.length - 1;
    notifyListeners();
    return newTab;
  }

  TabModel openInTabGroup({required String url, bool isIncognito = false}) {
    print("[TAB GROUP DEBUG] openInTabGroup triggered for URL: $url");
    try {
      TabGroup group;
      if (_groups.isNotEmpty) {
        group = _groups.last;
        print("[TAB GROUP DEBUG] Existing active tab group found: ${group.name} (${group.id})");
      } else {
        // Create new tab group
        final groupId = _uuid.v4();
        String domainName = 'Workspace';
        try {
          final uri = Uri.parse(url);
          final host = uri.host.replaceAll('www.', '');
          if (host.isNotEmpty) {
            domainName = host;
          }
        } catch (_) {}
        
        group = TabGroup(
          id: groupId,
          name: '$domainName Group',
          color: Colors.indigo,
          createdAt: DateTime.now(),
        );
        _groups.add(group);
        print("[TAB GROUP DEBUG] No active tab group found. Created new group: ${group.name} (${group.id})");
      }

      final tabId = _uuid.v4();
      final newTab = TabModel(
        id: tabId,
        url: url,
        isIncognito: isIncognito || _isGlobalIncognito,
        groupId: group.id,
        groupName: group.name,
        groupColor: group.color,
        groupCreatedAt: group.createdAt,
      );

      group.tabs.add(newTab);
      
      // Update tab counts
      for (var tab in group.tabs) {
        tab.groupTabCount = group.tabs.length;
      }

      print("[TAB GROUP DEBUG] Created grouped tab: $tabId, successfully inserted into group's tab collection.");

      final allTabs = tabs;
      _currentIndex = allTabs.indexWhere((t) => t.id == tabId);

      notifyListeners();
      return newTab;
    } catch (e) {
      print("[TAB GROUP ERROR] Failed to create or assign tab group: $e");
      throw Exception("Tab group creation failed: $e");
    }
  }

  void toggleDesktopMode(int index) {
    final allTabs = tabs;
    allTabs[index].isDesktopMode = !allTabs[index].isDesktopMode;
    final controller = allTabs[index].controller;
    if (controller != null) {
      controller.setSettings(settings: InAppWebViewSettings(
        preferredContentMode: allTabs[index].isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE,
        userAgent: allTabs[index].isDesktopMode 
          ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
          : '',
      ));
      controller.reload();
    }
    notifyListeners();
  }

  void switchTab(int index) {
    final allTabs = tabs;
    if (index >= 0 && index < allTabs.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    final allTabs = tabs;
    if (index >= 0 && index < allTabs.length) {
      final tab = allTabs[index];
      if (tab.isIncognito) {
        try {
          tab.controller?.clearCache();
          CookieManager.instance().deleteAllCookies();
          tab.controller?.evaluateJavascript(source: "window.localStorage.clear(); window.sessionStorage.clear();");
          print("[INCOGNITO DEBUG] Cleared cookies, cache, and storage for closed incognito tab.");
        } catch (e) {
          print("[INCOGNITO ERROR] Failed to clean incognito tab data: $e");
        }
      }

      if (tab.groupId != null) {
        final groupIndex = _groups.indexWhere((g) => g.id == tab.groupId);
        if (groupIndex != -1) {
          _groups[groupIndex].tabs.remove(tab);
          if (_groups[groupIndex].tabs.isEmpty) {
            _groups.removeAt(groupIndex);
          } else {
            for (var t in _groups[groupIndex].tabs) {
              t.groupTabCount = _groups[groupIndex].tabs.length;
            }
          }
        }
      } else {
        _standaloneTabs.remove(tab);
      }

      if (_isGlobalIncognito) {
        final hasAnyIncognitoLeft = tabs.any((t) => t.isIncognito);
        if (!hasAnyIncognitoLeft) {
          setGlobalIncognito(false);
        }
      }

      final remainingTabs = tabs;
      if (remainingTabs.isEmpty) {
        _currentIndex = -1;
        addNewTab(); // Always keep one tab open
      } else {
        if (_currentIndex >= remainingTabs.length) {
          _currentIndex = remainingTabs.length - 1;
        }
      }
      notifyListeners();
    }
  }

  void updateTab(String id, {String? url, String? title, double? progress}) {
    final allTabs = tabs;
    final index = allTabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      if (url != null) allTabs[index].url = url;
      if (title != null) allTabs[index].title = title;
      if (progress != null) allTabs[index].updateProgress(progress);
      notifyListeners();
    }
  }

  void toggleFindInPage() {
    _isFindingInPage = !_isFindingInPage;
    notifyListeners();
  }
}
