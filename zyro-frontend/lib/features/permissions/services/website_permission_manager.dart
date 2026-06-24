import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import '../controllers/website_permissions_controller.dart';
import '../models/permission_enums.dart';
import '../models/website_permission_rule.dart';
import '../widgets/permission_request_dialog.dart';
import 'domain_normalizer.dart';

class WebsitePermissionManager {
  WebsitePermissionManager._();
  static final instance = WebsitePermissionManager._();
  final controller = WebsitePermissionsController();
  Future<void>? _loading;

  Future<void> initialize() => _loading ??= controller.load();

  Future<bool> resolve(
    BuildContext context,
    String origin,
    PermissionType type,
  ) async {
    await initialize();
    final site = DomainNormalizer.normalize(origin);
    if (kDebugMode) {
      debugPrint('[WEBSITE PERMISSIONS] domain normalized: ${site.domain}');
      debugPrint(
        '[WEBSITE PERMISSIONS] request received: ${site.domain} ${type.name}',
      );
    }
    final existing = controller.ruleFor(site.domain, type);
    if (existing != null && kDebugMode) {
      debugPrint(
        '[WEBSITE PERMISSIONS] saved rule found: ${existing.status.name}',
      );
    }
    var selection = existing?.status;
    if (selection == PermissionStatus.block) {
      if (kDebugMode)
        debugPrint('[WEBSITE PERMISSIONS] permission blocked by saved rule');
      return false;
    }
    if (selection == null || selection == PermissionStatus.ask) {
      if (kDebugMode)
        debugPrint('[WEBSITE PERMISSIONS] prompt shown for ${site.domain}');
      selection = await PermissionRequestDialog.show(
        context,
        site.domain,
        type,
      );
      final now = DateTime.now();
      await controller.upsert(
        WebsitePermissionRule(
          id: '${site.domain}:${type.name}',
          domain: site.domain,
          origin: site.origin,
          permissionType: type,
          status: selection,
          lastRequestedAt: now,
          lastUpdatedAt: now,
          source: 'webview',
        ),
      );
    }
    if (selection == PermissionStatus.block) return false;
    if (!await _requestAndroidPermission(type)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Android permission was denied.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (kDebugMode)
        debugPrint('[WEBSITE PERMISSIONS] Android permission denied');
      return false;
    }
    if (kDebugMode) debugPrint('[WEBSITE PERMISSIONS] permission allowed');
    return true;
  }

  Future<bool> _requestAndroidPermission(PermissionType type) async {
    final permissions = switch (type) {
      PermissionType.camera => [Permission.camera],
      PermissionType.microphone => [Permission.microphone],
      PermissionType.location => [Permission.locationWhenInUse],
      PermissionType.notifications => [Permission.notification],
      PermissionType.clipboard => <Permission>[],
    };
    if (permissions.isEmpty) return true;
    if (kDebugMode)
      debugPrint('[WEBSITE PERMISSIONS] Android runtime permission requested');
    final results = await permissions.request();
    return results.values.every((status) => status.isGranted);
  }
}
