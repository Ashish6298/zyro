import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/history_item.dart';
import 'models/bookmark_item.dart';

class BrowserDataManager extends ChangeNotifier {
  final List<HistoryItem> _history = [];
  final List<BookmarkItem> _bookmarks = [];
  final List<String> _downloads = []; // Simple for now
  final _uuid = const Uuid();

  List<HistoryItem> get history => List.unmodifiable(_history);
  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);
  List<String> get downloads => List.unmodifiable(_downloads);

  void addHistory(String url, String title) {
    if (_history.isNotEmpty && _history.last.url == url) return;
    _history.add(HistoryItem(
      id: _uuid.v4(),
      url: url,
      title: title,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void toggleBookmark(String url, String title) {
    final index = _bookmarks.indexWhere((b) => b.url == url);
    if (index != -1) {
      _bookmarks.removeAt(index);
    } else {
      _bookmarks.add(BookmarkItem(
        id: _uuid.v4(),
        url: url,
        title: title,
      ));
    }
    notifyListeners();
  }

  void clearBookmarks() {
    _bookmarks.clear();
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }

  void addDownload(String url) {
    _downloads.add(url);
    notifyListeners();
  }

  void clearDownloads() {
    _downloads.clear();
    notifyListeners();
  }
}
