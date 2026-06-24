import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/permission_enums.dart';

class PermissionSummaryCard extends StatelessWidget {
  final PermissionType type;
  final int count;
  final VoidCallback onTap;
  const PermissionSummaryCard({
    super.key,
    required this.type,
    required this.count,
    required this.onTap,
  });

  IconData get _icon => switch (type) {
    PermissionType.camera => LucideIcons.camera,
    PermissionType.microphone => LucideIcons.mic,
    PermissionType.location => LucideIcons.mapPin,
    PermissionType.notifications => LucideIcons.bell,
    PermissionType.clipboard => LucideIcons.clipboard,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(.08),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    type == PermissionType.clipboard && count == 0
                        ? 'Managed access'
                        : '$count website${count == 1 ? '' : 's'} configured',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 17,
              color: theme.colorScheme.onSurface.withOpacity(.35),
            ),
          ],
        ),
      ),
    );
  }
}
