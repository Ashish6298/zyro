import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'models/extension_model.dart';
import 'services/extension_storage_service.dart';
import 'services/extension_notification_service.dart';

class ExtensionManager extends ChangeNotifier {
  final List<ExtensionModel> _installedExtensions = [];
  final List<ExtensionModel> _availableExtensions = [];

  List<ExtensionModel> get installedExtensions => _installedExtensions;
  List<ExtensionModel> get availableExtensions => _availableExtensions;

  ExtensionManager() {
    _init();
  }

  Future<void> _init() async {
    await ExtensionStorageService.removeFloatingVideosState();
    final savedStates = await ExtensionStorageService.loadExtensionStates();

    final List<ExtensionModel> defaults = [
      ExtensionModel(
        id: 'ad_blocker_downloader',
        name: 'Ad Blocker & Downloader',
        description:
            'Blocks ads and detects/downloads videos on YouTube and other websites.',
        version: '1.0.0',
        icon: LucideIcons.shieldAlert,
        isEnabled: true,
        isInstalled: true,
        downloadedAt: DateTime.now(),
        currentState: 'active',
      ),
      ExtensionModel(
        id: 'dev_tools',
        name: 'Dev Tools',
        description:
            'Developer tools including element inspector, console, network logging, and storage explorer.',
        version: '1.0.0',
        icon: LucideIcons.code,
      ),
      ExtensionModel(
        id: 'background_player',
        name: 'Background Player',
        description:
            'Enables background media playback with system notification controls.',
        version: '1.0.0',
        icon: LucideIcons.playCircle,
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

    if (savedStates.isEmpty) {
      // First run: populate from defaults
      for (var ext in defaults) {
        if (ext.isInstalled) {
          _installedExtensions.add(ext);
        } else {
          _availableExtensions.add(ext);
        }
      }
      await ExtensionStorageService.saveExtensionStates([
        ..._installedExtensions,
        ..._availableExtensions,
      ]);
    } else {
      // Merge saved states with default definitions
      for (var def in defaults) {
        final saved = savedStates.firstWhere(
          (s) => s['id'] == def.id,
          orElse: () => {},
        );
        if (saved.isNotEmpty) {
          final ext = ExtensionModel.fromMap(saved);
          final mergedExt = ExtensionModel(
            id: ext.id,
            name: def.name,
            description: def.description,
            version: def.version,
            icon: def.icon,
            isEnabled: ext.isEnabled,
            isInstalled: ext.isInstalled,
            downloadedAt: ext.downloadedAt,
            updatedAt: ext.updatedAt,
            lastEnabledAt: ext.lastEnabledAt,
            lastDisabledAt: ext.lastDisabledAt,
            currentState: ext.currentState,
          );
          if (mergedExt.isInstalled) {
            _installedExtensions.add(mergedExt);
          } else {
            _availableExtensions.add(mergedExt);
          }
        } else {
          // If not in saved states, keep as available default
          _availableExtensions.add(def);
        }
      }
    }
    notifyListeners();
  }

  void toggleExtension(String id) {
    final index = _installedExtensions.indexWhere((e) => e.id == id);
    if (index != -1) {
      final ext = _installedExtensions[index];
      ext.isEnabled = !ext.isEnabled;
      ext.updatedAt = DateTime.now();
      if (ext.isEnabled) {
        ext.lastEnabledAt = DateTime.now();
        ext.currentState = 'active';
      } else {
        ext.lastDisabledAt = DateTime.now();
        ext.currentState = 'inactive';
      }

      ExtensionStorageService.saveExtensionStates([
        ..._installedExtensions,
        ..._availableExtensions,
      ]);
      notifyListeners();

      // Trigger user manual toggle notification
      ExtensionNotificationService.showToggleNotification(
        ext.name,
        ext.id,
        ext.isEnabled,
      );
    }
  }

  bool isExtensionEnabled(String id) {
    return _installedExtensions.any((e) => e.id == id && e.isEnabled);
  }

  void installExtension(ExtensionModel extension) {
    if (!_installedExtensions.any((e) => e.id == extension.id)) {
      extension.isInstalled = true;
      extension.isEnabled = false;
      extension.downloadedAt = DateTime.now();
      extension.updatedAt = DateTime.now();

      _installedExtensions.add(extension);
      _availableExtensions.removeWhere((e) => e.id == extension.id);

      ExtensionStorageService.saveExtensionStates([
        ..._installedExtensions,
        ..._availableExtensions,
      ]);
      notifyListeners();
    }
  }

  void uninstallExtension(String id) {
    final index = _installedExtensions.indexWhere((e) => e.id == id);
    if (index != -1) {
      final ext = _installedExtensions[index];
      ext.isInstalled = false;
      ext.isEnabled = false;
      ext.currentState = 'inactive';
      ext.updatedAt = DateTime.now();

      _availableExtensions.add(ext);
      _installedExtensions.removeAt(index);

      ExtensionStorageService.saveExtensionStates([
        ..._installedExtensions,
        ..._availableExtensions,
      ]);
      notifyListeners();

      // Trigger notification
      ExtensionNotificationService.showRemoveNotification(ext.name);
    }
  }
}
