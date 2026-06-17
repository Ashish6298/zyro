import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';
import 'models/tab_model.dart';

class TabManager extends ChangeNotifier {
  final List<TabModel> _tabs = [];
  int _currentIndex = -1;
  bool _isFindingInPage = false;
  final _uuid = const Uuid();

  List<TabModel> get tabs => _tabs;
  int get currentIndex => _currentIndex;
  bool get isFindingInPage => _isFindingInPage;
  
  TabModel? get currentTab => _currentIndex != -1 ? _tabs[_currentIndex] : null;

  void addNewTab({String? url}) {
    final newTab = TabModel(
      id: _uuid.v4(),
      url: url ?? 'https://www.google.com',
    );
    _tabs.add(newTab);
    _currentIndex = _tabs.length - 1;
    notifyListeners();
  }

  void toggleDesktopMode(int index) {
    tabs[index].isDesktopMode = !tabs[index].isDesktopMode;
    final controller = tabs[index].controller;
    if (controller != null) {
      controller.setSettings(settings: InAppWebViewSettings(
        preferredContentMode: tabs[index].isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE,
        userAgent: tabs[index].isDesktopMode 
          ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
          : '',
      ));
      controller.reload();
    }
    notifyListeners();
  }

  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _tabs.removeAt(index);
      if (_tabs.isEmpty) {
        _currentIndex = -1;
        addNewTab(); // Always keep one tab open
      } else {
        if (_currentIndex >= _tabs.length) {
          _currentIndex = _tabs.length - 1;
        }
      }
      notifyListeners();
    }
  }

  void updateTab(String id, {String? url, String? title, double? progress}) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      if (url != null) _tabs[index].url = url;
      if (title != null) _tabs[index].title = title;
      if (progress != null) _tabs[index].updateProgress(progress);
      notifyListeners();
    }
  }

  void toggleFindInPage() {
    _isFindingInPage = !_isFindingInPage;
    notifyListeners();
  }
}
