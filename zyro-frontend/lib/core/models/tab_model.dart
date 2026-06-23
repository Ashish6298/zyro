import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TabGroup {
  final String id;
  String name;
  Color color;
  final DateTime createdAt;
  final List<TabModel> tabs = [];

  TabGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });
}

class TabModel {
  final String id;
  final GlobalKey webViewKey = GlobalKey();
  String url;
  String? title;
  Favicon? favicon;
  double progress;
  bool isLoading;
  bool isDesktopMode;
  
  // Additional persistent metadata
  DateTime? lastVisitedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isActive;
  bool canGoBack;
  bool canGoForward;
  double? scrollX;
  double? scrollY;

  // Tab Group Metadata
  String? groupId;
  String? groupName;
  Color? groupColor;
  DateTime? groupCreatedAt;
  int? groupTabCount;

  bool isIncognito;
  InAppWebViewController? controller;

  TabModel({
    required this.id,
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.progress = 0,
    this.isLoading = false,
    this.isDesktopMode = false,
    this.lastVisitedAt,
    this.createdAt,
    this.updatedAt,
    this.isActive = false,
    this.canGoBack = false,
    this.canGoForward = false,
    this.scrollX,
    this.scrollY,
    this.groupId,
    this.groupName,
    this.groupColor,
    this.groupCreatedAt,
    this.groupTabCount,
    this.isIncognito = false,
  }) {
    createdAt ??= DateTime.now();
    lastVisitedAt ??= DateTime.now();
    updatedAt ??= DateTime.now();
  }

  factory TabModel.fromMap(Map<String, dynamic> map) {
    Favicon? fav;
    if (map['faviconUrl'] != null) {
      try {
        fav = Favicon(url: WebUri(map['faviconUrl']));
      } catch (_) {}
    }

    return TabModel(
      id: map['id'] ?? '',
      url: map['url'] ?? 'about:blank',
      title: map['title'] ?? 'New Tab',
      isDesktopMode: map['isDesktopMode'] ?? false,
      lastVisitedAt: map['lastVisitedAt'] != null ? DateTime.tryParse(map['lastVisitedAt']) : null,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      isActive: map['isActive'] ?? false,
      canGoBack: map['canGoBack'] ?? false,
      canGoForward: map['canGoForward'] ?? false,
      scrollX: map['scrollX'] != null ? (map['scrollX'] as num).toDouble() : null,
      scrollY: map['scrollY'] != null ? (map['scrollY'] as num).toDouble() : null,
      groupId: map['groupId'],
      groupName: map['groupName'],
      groupColor: map['groupColor'] != null ? Color(map['groupColor']) : null,
      groupCreatedAt: map['groupCreatedAt'] != null ? DateTime.tryParse(map['groupCreatedAt']) : null,
      groupTabCount: map['groupTabCount'],
    )..favicon = fav;
  }

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
