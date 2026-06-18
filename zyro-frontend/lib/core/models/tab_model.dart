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
  String url;
  String? title;
  Favicon? favicon;
  double progress;
  bool isLoading;
  bool isDesktopMode;
  
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
    this.groupId,
    this.groupName,
    this.groupColor,
    this.groupCreatedAt,
    this.groupTabCount,
    this.isIncognito = false,
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
