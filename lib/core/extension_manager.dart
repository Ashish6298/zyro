import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models/extension_model.dart';

class ExtensionManager extends ChangeNotifier {
  final List<ExtensionModel> _installedExtensions = [
    ExtensionModel(
      id: 'ad_blocker',
      name: 'Ad Blocker',
      description: 'Blocks annoying ads on YouTube and other websites.',
      version: '1.0.0',
      icon: LucideIcons.shieldAlert,
      isEnabled: true,
    ),
  ];

  final List<ExtensionModel> _availableExtensions = [
    ExtensionModel(
      id: 'video_downloader',
      name: 'Video Downloader',
      description: 'Detects videos on any page and provides high-quality download options.',
      version: '1.0.5',
      icon: LucideIcons.download,
    ),
    ExtensionModel(
      id: 'dark_mode',
      name: 'Dark Reader',
      description: 'Enable high-quality dark mode for every website.',
      version: '1.2.0',
      icon: LucideIcons.moon,
    ),
    ExtensionModel(
      id: 'password_gen',
      name: 'KeyGen',
      description: 'Generate and manage strong passwords.',
      version: '0.9.5',
      icon: LucideIcons.key,
    ),
  ];

  List<ExtensionModel> get installedExtensions => _installedExtensions;
  List<ExtensionModel> get availableExtensions => _availableExtensions;

  void toggleExtension(String id) {
    final index = _installedExtensions.indexWhere((e) => e.id == id);
    if (index != -1) {
      _installedExtensions[index].isEnabled = !_installedExtensions[index].isEnabled;
      notifyListeners();
    }
  }

  bool isExtensionEnabled(String id) {
    return _installedExtensions.any((e) => e.id == id && e.isEnabled);
  }

  void installExtension(ExtensionModel extension) {
    if (!_installedExtensions.any((e) => e.id == extension.id)) {
      _installedExtensions.add(extension);
      _availableExtensions.removeWhere((e) => e.id == extension.id);
      notifyListeners();
    }
  }
}
