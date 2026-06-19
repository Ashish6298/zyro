import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';
import 'models/tab_model.dart';
import 'globals.dart';
import 'services/tab_session_storage_service.dart';

class RecentlyClosedTab {
  final TabModel tab;
  final int originalGlobalIndex;
  final int originalStandaloneIndex;
  final int originalGroupIndex;
  final TabGroup? group;

  RecentlyClosedTab({
    required this.tab,
    required this.originalGlobalIndex,
    required this.originalStandaloneIndex,
    required this.originalGroupIndex,
    this.group,
  });
}

class TabManager extends ChangeNotifier with WidgetsBindingObserver {
  final List<TabModel> _standaloneTabs = [];
  final List<TabGroup> _groups = [];
  int _currentIndex = -1;
  bool _isFindingInPage = false;
  bool _isGlobalIncognito = false;
  final _uuid = const Uuid();

  RecentlyClosedTab? _recentlyClosedTab;
  Timer? _undoTimer;

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

  TabManager() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _undoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      print("[TAB LIFECYCLE LOG] App state changed to $state. Saving session...");
      saveSession();
    }
  }

  Future<void> saveSession() async {
    final allTabs = tabs;
    for (int i = 0; i < allTabs.length; i++) {
      allTabs[i].isActive = (i == _currentIndex);
      if (i == _currentIndex) {
        allTabs[i].lastVisitedAt = DateTime.now();
      }
    }
    await TabSessionStorageService.saveSession(
      standaloneTabs: _standaloneTabs,
      groups: _groups,
      currentIndex: _currentIndex,
    );
  }

  Future<bool> restoreSession() async {
    print("[TAB PERSISTENCE LOG] Restoring normal tab session...");
    final data = await TabSessionStorageService.loadSession();
    if (data == null) {
      print("[TAB PERSISTENCE LOG] No saved session found.");
      return false;
    }

    try {
      final List<dynamic> standaloneData = data['standaloneTabs'] ?? [];
      final List<dynamic> groupsData = data['groups'] ?? [];
      final int savedIndex = data['currentIndex'] ?? -1;

      _standaloneTabs.clear();
      _groups.clear();

      for (var map in standaloneData) {
        _standaloneTabs.add(TabModel.fromMap(Map<String, dynamic>.from(map)));
      }

      for (var gMap in groupsData) {
        final g = Map<String, dynamic>.from(gMap);
        final group = TabGroup(
          id: g['id'],
          name: g['name'],
          color: Color(g['color']),
          createdAt: DateTime.parse(g['createdAt']),
        );
        final List<dynamic> tList = g['tabs'] ?? [];
        for (var tMap in tList) {
          group.tabs.add(TabModel.fromMap(Map<String, dynamic>.from(tMap)));
        }
        _groups.add(group);
      }

      if (tabs.isEmpty) {
        print("[TAB PERSISTENCE LOG] Restored session yielded 0 tabs. Aborting restore.");
        return false;
      }

      _currentIndex = savedIndex;
      if (_currentIndex < 0 || _currentIndex >= tabs.length) {
        _currentIndex = 0;
      }

      print("[TAB PERSISTENCE LOG] Tab session restored. Total tabs: ${tabs.length}, Active Index: $_currentIndex");
      notifyListeners();
      return true;
    } catch (e) {
      print("[TAB PERSISTENCE ERROR LOG] Error restoring tab session: $e");
      return false;
    }
  }

  Future<void> loadSavedSessionOrDefault() async {
    final success = await restoreSession();
    if (!success) {
      addNewTab();
    }
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
            InAppWebViewController.clearAllCache();
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
    saveSession();
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
    saveSession();
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

      saveSession();
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
    saveSession();
    notifyListeners();
  }

  void switchTab(int index) {
    final allTabs = tabs;
    if (index >= 0 && index < allTabs.length) {
      _currentIndex = index;
      saveSession();
      notifyListeners();
    }
  }

  void closeTab(int index) {
    final allTabs = tabs;
    if (index >= 0 && index < allTabs.length) {
      final tab = allTabs[index];
      
      final standaloneIndex = _standaloneTabs.indexOf(tab);
      int groupIndex = -1;
      TabGroup? groupObj;
      if (tab.groupId != null) {
        final gIdx = _groups.indexWhere((g) => g.id == tab.groupId);
        if (gIdx != -1) {
          groupObj = _groups[gIdx];
          groupIndex = groupObj.tabs.indexOf(tab);
        }
      }

      if (tab.isIncognito) {
        try {
          InAppWebViewController.clearAllCache();
          CookieManager.instance().deleteAllCookies();
          tab.controller?.evaluateJavascript(source: "window.localStorage.clear(); window.sessionStorage.clear();");
          print("[INCOGNITO DEBUG] Cleared cookies, cache, and storage for closed incognito tab.");
        } catch (e) {
          print("[INCOGNITO ERROR] Failed to clean incognito tab data: $e");
        }
      }

      // Close logic
      if (tab.groupId != null && groupObj != null) {
        groupObj.tabs.remove(tab);
        if (groupObj.tabs.isEmpty) {
          _groups.remove(groupObj);
        } else {
          for (var t in groupObj.tabs) {
            t.groupTabCount = groupObj.tabs.length;
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

      // Setup RecentlyClosedTab & Undo SnackBar for normal tabs
      if (!tab.isIncognito) {
        _recentlyClosedTab = RecentlyClosedTab(
          tab: tab,
          originalGlobalIndex: index,
          originalStandaloneIndex: standaloneIndex,
          originalGroupIndex: groupIndex,
          group: groupObj,
        );

        _undoTimer?.cancel();
        _undoTimer = Timer(const Duration(seconds: 5), () {
          _recentlyClosedTab = null;
          print("[TAB PERSISTENCE LOG] Undo window expired. finalizing tab close state.");
          saveSession();
        });

        // Show SnackBar
        try {
          globalScaffoldKey.currentState?.clearSnackBars();
          globalScaffoldKey.currentState?.showSnackBar(
            SnackBar(
              content: const Text(
                'Tab closed',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.blueGrey.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Colors.cyanAccent,
                onPressed: () {
                  undoCloseTab();
                },
              ),
            ),
          );
        } catch (e) {
          print("Error showing Undo SnackBar: $e");
        }
      }

      saveSession();
      notifyListeners();
    }
  }

  void undoCloseTab() {
    if (_recentlyClosedTab == null) return;
    _undoTimer?.cancel();
    final closed = _recentlyClosedTab!;
    
    if (closed.group != null) {
      final groupExists = _groups.any((g) => g.id == closed.group!.id);
      if (!groupExists) {
        _groups.add(closed.group!);
      }
      
      final group = _groups.firstWhere((g) => g.id == closed.group!.id);
      if (closed.originalGroupIndex >= 0 && closed.originalGroupIndex <= group.tabs.length) {
        group.tabs.insert(closed.originalGroupIndex, closed.tab);
      } else {
        group.tabs.add(closed.tab);
      }
      
      for (var t in group.tabs) {
        t.groupTabCount = group.tabs.length;
      }
    } else {
      if (closed.originalStandaloneIndex >= 0 && closed.originalStandaloneIndex <= _standaloneTabs.length) {
        _standaloneTabs.insert(closed.originalStandaloneIndex, closed.tab);
      } else {
        _standaloneTabs.add(closed.tab);
      }
    }

    _currentIndex = closed.originalGlobalIndex;
    if (_currentIndex >= tabs.length) {
      _currentIndex = tabs.length - 1;
    }
    
    _recentlyClosedTab = null;
    print("[TAB UNDO LOG] Tab successfully undo-restored: ${closed.tab.title}");
    
    saveSession();
    notifyListeners();
  }

  void updateTab(String id, {
    String? url,
    String? title,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
    double? scrollX,
    double? scrollY,
  }) {
    final allTabs = tabs;
    final index = allTabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      final tab = allTabs[index];
      if (url != null) tab.url = url;
      if (title != null) tab.title = title;
      if (progress != null) tab.updateProgress(progress);
      if (canGoBack != null) tab.canGoBack = canGoBack;
      if (canGoForward != null) tab.canGoForward = canGoForward;
      if (scrollX != null) tab.scrollX = scrollX;
      if (scrollY != null) tab.scrollY = scrollY;
      tab.updatedAt = DateTime.now();
      saveSession();
      notifyListeners();
    }
  }

  void updateTabScroll(String id, double x, double y) {
    final allTabs = tabs;
    final index = allTabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      allTabs[index].scrollX = x;
      allTabs[index].scrollY = y;
    }
  }

  void toggleFindInPage() {
    _isFindingInPage = !_isFindingInPage;
    notifyListeners();
  }
}
