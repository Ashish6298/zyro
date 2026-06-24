import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/permission_enums.dart';

class PermissionRequestDialog extends StatelessWidget {
  final String domain;
  final PermissionType type;
  const PermissionRequestDialog({
    super.key,
    required this.domain,
    required this.type,
  });

  static Future<PermissionStatus> show(
    BuildContext context,
    String domain,
    PermissionType type,
  ) async {
    return await showDialog<PermissionStatus>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PermissionRequestDialog(domain: domain, type: type),
        ) ??
        PermissionStatus.block;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'WEBSITE PERMISSION',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        '$domain wants to access your ${type.label.toLowerCase()}.',
        style: GoogleFonts.outfit(
          color: theme.colorScheme.onSurface.withOpacity(.75),
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, PermissionStatus.block),
          child: const Text('Block'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, PermissionStatus.ask),
          child: const Text('Ask Every Time'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, PermissionStatus.allow),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
