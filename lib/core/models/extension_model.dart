import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/widgets.dart';

class ExtensionModel {
  final String id;
  final String name;
  final String description;
  final String version;
  final IconData icon;
  bool isEnabled;

  ExtensionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.icon,
    this.isEnabled = false,
  });
}
