import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TabModel {
  final String id;
  String url;
  String? title;
  Favicon? favicon;
  double progress;
  bool isLoading;
  bool isDesktopMode;
  InAppWebViewController? controller;

  TabModel({
    required this.id,
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.progress = 0,
    this.isLoading = false,
    this.isDesktopMode = false,
  });

  void updateUrl(String newUrl) {
    url = newUrl;
  }

  void updateTitle(String newTitle) {
    title = newTitle;
  }

  void updateProgress(double newProgress) {
    progress = newProgress;
    isLoading = newProgress < 1.0;
  }
}
