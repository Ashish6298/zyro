import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/ad_block_stats_service.dart';

class AdBlockSettingsStatsWidget extends StatelessWidget {
  const AdBlockSettingsStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsService = context.watch<AdBlockStatsService>();
    final stats = statsService.stats;
    final hasStats = stats.totalBlocked > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'AD BLOCKER STATUS'),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [theme.cardColor.withOpacity(0.6), theme.cardColor.withOpacity(0.3)]
                  : [theme.cardColor, theme.cardColor.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? theme.dividerColor.withOpacity(0.08) : theme.dividerColor.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBentoStatCard(
                      theme,
                      'Total Blocked',
                      stats.totalBlocked.toString(),
                      LucideIcons.shieldAlert,
                      theme.colorScheme.primary,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoStatCard(
                      theme,
                      'Blocked Today',
                      stats.todayBlocked.toString(),
                      LucideIcons.zap,
                      Colors.orangeAccent,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasStats) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDetailsBottomSheet(context, statsService),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(isDark ? 0.08 : 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.barChart2,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Analytics Breakdown',
                            style: GoogleFonts.outfit(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your connection is fully secured',
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.04),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.12 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: theme.colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context, AdBlockStatsService statsService) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedBuilder(
              animation: statsService,
              builder: (context, _) {
                final stats = statsService.stats;
                final sortedDomains = stats.domainBlockedCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final hasDomains = sortedDomains.isNotEmpty;

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(
                      color: isDark ? theme.dividerColor.withOpacity(0.08) : theme.dividerColor.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 14, bottom: 8),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AdBlock Analytics',
                              style: GoogleFonts.outfit(
                                color: theme.colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (hasDomains)
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withOpacity(isDark ? 0.12 : 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(LucideIcons.trash2, color: theme.colorScheme.error, size: 16),
                                ),
                                onPressed: () async {
                                  final didClear = await _confirmReset(context, statsService);
                                  if (didClear && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Summary metrics inside bottom sheet
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBentoStatCard(
                                theme,
                                'Total Blocked',
                                stats.totalBlocked.toString(),
                                LucideIcons.shieldAlert,
                                theme.colorScheme.primary,
                                isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBentoStatCard(
                                theme,
                                'Blocked Today',
                                stats.todayBlocked.toString(),
                                LucideIcons.zap,
                                Colors.orangeAccent,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Domain list with progress indicators
                      Flexible(
                        child: hasDomains
                            ? ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                physics: const BouncingScrollPhysics(),
                                itemCount: sortedDomains.length,
                                itemBuilder: (context, index) {
                                  final entry = sortedDomains[index];
                                  final double percentage = stats.totalBlocked > 0
                                      ? (entry.value / stats.totalBlocked)
                                      : 0.0;
                                  
                                  // First letter of domain for visual avatar
                                  final String initial = entry.key.isNotEmpty
                                      ? entry.key.replaceAll('www.', '').substring(0, 1).toUpperCase()
                                      : 'G';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.04),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                                                    child: Text(
                                                      initial,
                                                      style: GoogleFonts.outfit(
                                                        color: theme.colorScheme.primary,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      entry.key,
                                                      style: GoogleFonts.outfit(
                                                        color: theme.colorScheme.onSurface,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                entry.value.toString(),
                                                style: GoogleFonts.outfit(
                                                  color: theme.colorScheme.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(2),
                                                child: LinearProgressIndicator(
                                                  value: percentage,
                                                  backgroundColor: theme.dividerColor.withOpacity(0.06),
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.primary.withOpacity(0.7),
                                                  ),
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${(percentage * 100).toStringAsFixed(0)}%',
                                              style: GoogleFonts.outfit(
                                                color: theme.colorScheme.onSurface.withOpacity(0.3),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'No websites logged yet',
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmReset(BuildContext context, AdBlockStatsService statsService) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Statistics',
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Clear ad-block statistics? This will remove all blocked ad counts and website logs.',
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: theme.colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await statsService.clearStats();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ad-block statistics cleared.',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return true;
    }
    return false;
  }
}
