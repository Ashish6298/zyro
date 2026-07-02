import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/website_vault_domain_summary.dart';
import '../models/website_vault_type.dart';

class WebsiteVaultDomainCard extends StatelessWidget {
  final WebsiteVaultDomainSummary summary;
  final VoidCallback onTap;

  const WebsiteVaultDomainCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chips = summary.typeCounts.entries
        .where((entry) => entry.value > 0)
        .take(5)
        .toList();
    final name = _displayName(summary.domain);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 1),
      duration: const Duration(milliseconds: 160),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.cardColor.withValues(alpha: 0.72)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.26),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.055),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Favicon(url: summary.faviconUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            summary.domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.44,
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Items',
                        value: summary.itemCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Metric(
                        label: 'Storage',
                        value: _formatBytes(summary.totalStorageBytes),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: chips.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _iconFor(entry.key),
                            size: 11,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.key.label,
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Updated ${_relativeDate(summary.latestItemAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.44,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _QuickIcon(icon: LucideIcons.search, onTap: onTap),
                    const SizedBox(width: 6),
                    _QuickIcon(icon: LucideIcons.externalLink, onTap: onTap),
                    const SizedBox(width: 6),
                    _QuickIcon(icon: LucideIcons.moreHorizontal, onTap: onTap),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayName(String domain) {
    final root = domain.split('.').first;
    if (root.isEmpty) return domain;
    return root[0].toUpperCase() + root.substring(1);
  }

  String _relativeDate(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${value.day}/${value.month}/${value.year}';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconFor(WebsiteVaultType type) {
    switch (type) {
      case WebsiteVaultType.screenshot:
        return LucideIcons.image;
      case WebsiteVaultType.pdf:
        return LucideIcons.fileText;
      case WebsiteVaultType.link:
        return LucideIcons.link;
      case WebsiteVaultType.download:
        return LucideIcons.download;
      case WebsiteVaultType.note:
        return LucideIcons.stickyNote;
      case WebsiteVaultType.receipt:
        return LucideIcons.receipt;
      case WebsiteVaultType.page:
        return LucideIcons.file;
    }
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuickIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 13),
      ),
    );
  }
}

class _Favicon extends StatelessWidget {
  final String? url;

  const _Favicon({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: url == null
            ? Icon(LucideIcons.archive, color: theme.colorScheme.primary)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(LucideIcons.archive, color: theme.colorScheme.primary),
              ),
      ),
    );
  }
}
