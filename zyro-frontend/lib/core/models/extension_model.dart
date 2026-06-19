import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExtensionModel {
  final String id;
  final String name;
  final String description;
  final String version;
  final IconData icon;
  bool isEnabled;
  bool isInstalled;
  
  DateTime? downloadedAt;
  DateTime? updatedAt;
  DateTime? lastEnabledAt;
  DateTime? lastDisabledAt;
  String currentState; // 'active', 'inactive', etc.

  ExtensionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.icon,
    this.isEnabled = false,
    this.isInstalled = false,
    this.downloadedAt,
    this.updatedAt,
    this.lastEnabledAt,
    this.lastDisabledAt,
    this.currentState = 'inactive',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'isEnabled': isEnabled,
      'isInstalled': isInstalled,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastEnabledAt': lastEnabledAt?.toIso8601String(),
      'lastDisabledAt': lastDisabledAt?.toIso8601String(),
      'currentState': currentState,
    };
  }

  factory ExtensionModel.fromMap(Map<String, dynamic> map) {
    // Resolve icon from codePoint and font details
    final int codePoint = map['iconCodePoint'] ?? LucideIcons.puzzle.codePoint;
    final String? fontFamily = map['iconFontFamily'] ?? 'LucideIcons';
    final String? fontPackage = map['iconFontPackage'];

    return ExtensionModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      version: map['version'] ?? '',
      icon: IconData(codePoint, fontFamily: fontFamily, fontPackage: fontPackage),
      isEnabled: map['isEnabled'] ?? false,
      isInstalled: map['isInstalled'] ?? false,
      downloadedAt: map['downloadedAt'] != null ? DateTime.tryParse(map['downloadedAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      lastEnabledAt: map['lastEnabledAt'] != null ? DateTime.tryParse(map['lastEnabledAt']) : null,
      lastDisabledAt: map['lastDisabledAt'] != null ? DateTime.tryParse(map['lastDisabledAt']) : null,
      currentState: map['currentState'] ?? 'inactive',
    );
  }
}
