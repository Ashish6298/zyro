import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/usage_entry.dart';
import '../services/usage_format_service.dart';
import 'usage_progress_bar.dart';

class UsageWebsiteTile extends StatelessWidget {
  final UsageEntry entry;
  final int bytes;
  final int totalBytes;

  const UsageWebsiteTile({
    super.key,
    required this.entry,
    required this.bytes,
    required this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percent = totalBytes <= 0 ? 0.0 : bytes / totalBytes;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? theme.cardColor.withValues(alpha: 0.42)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.018),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 42,
              height: 42,
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              child: entry.faviconUrl == null
                  ? Icon(
                      LucideIcons.globe2,
                      color: theme.colorScheme.primary,
                      size: 20,
                    )
                  : Image.network(
                      entry.faviconUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        LucideIcons.globe2,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      UsageFormatService.bytes(bytes),
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                UsageProgressBar(value: percent),
                const SizedBox(height: 5),
                Text(
                  '${(percent * 100).clamp(0, 100).toStringAsFixed(1)}% • ${entry.requestCount} requests',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
