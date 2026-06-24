import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../controllers/website_permissions_controller.dart';
import '../models/permission_enums.dart';
import '../widgets/permission_summary_card.dart';
import 'permission_category_screen.dart';

class WebsitePermissionsScreen extends StatelessWidget {
  const WebsitePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WEBSITE PERMISSIONS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw),
            tooltip: 'Reset Permissions',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Consumer<WebsitePermissionsController>(
        builder: (context, controller, _) {
          if (!controller.loaded)
            return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'CONTROL WEBSITE ACCESS',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how websites can access your device. Changes are saved on this device.',
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              for (final type in PermissionType.values)
                PermissionSummaryCard(
                  type: type,
                  count: controller.countFor(type),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PermissionCategoryScreen(type: type),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.trash2),
                label: const Text('Clear All Permission Rules'),
                onPressed: () => _confirmClear(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all website permission rules?'),
        content: const Text('Websites will ask again when they need access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true && context.mounted)
      await context.read<WebsitePermissionsController>().clear();
  }
}
