import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../controllers/usage_controller.dart';
import '../services/usage_format_service.dart';
import '../services/usage_tracking_service.dart';
import '../widgets/usage_period_filter.dart';
import '../widgets/usage_summary_card.dart';
import '../widgets/usage_website_tile.dart';

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsageController(context.read<UsageTrackingService>()),
      child: const _UsageView(),
    );
  }
}

class _UsageView extends StatelessWidget {
  const _UsageView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'USAGE',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Estimated local data analytics',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear usage data',
            icon: const Icon(LucideIcons.trash2, size: 19),
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Consumer<UsageController>(
        builder: (context, controller, _) {
          final entries = controller.entries;
          final selectedTotal = controller.selectedTotalBytes;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            physics: const BouncingScrollPhysics(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: UsageSummaryCard(
                      label: 'This Month',
                      bytes: controller.monthlyBytes,
                      icon: LucideIcons.calendarDays,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: UsageSummaryCard(
                      label: 'Today',
                      bytes: controller.todayBytes,
                      icon: LucideIcons.activity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PrivacyNote(theme),
              const SizedBox(height: 16),
              UsagePeriodFilter(
                selected: controller.period,
                onChanged: controller.setPeriod,
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'TOP WEBSITES',
                trailing: UsageFormatService.bytes(selectedTotal),
              ),
              if (entries.isEmpty)
                _EmptyUsageCard(theme: theme)
              else
                ...entries.map(
                  (entry) => UsageWebsiteTile(
                    entry: entry,
                    bytes: controller.usageFor(entry),
                    totalBytes: selectedTotal,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Clear usage data?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Only local Usage Analytics totals will be reset. Browser history, downloads, tabs, bookmarks, and settings are not changed.',
            style: GoogleFonts.outfit(fontSize: 13, height: 1.35),
          ),
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
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<UsageController>().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usage data cleared'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;

  const _SectionHeader({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final ThemeData theme;

  const _PrivacyNote(this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Usage Analytics are stored locally on your device and are used only to show your browsing data usage inside Zyro. Values are estimated when exact response sizes are unavailable.',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsageCard extends StatelessWidget {
  final ThemeData theme;

  const _EmptyUsageCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.barChart3,
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'No usage recorded yet',
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Browse a website to start building local usage estimates.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
