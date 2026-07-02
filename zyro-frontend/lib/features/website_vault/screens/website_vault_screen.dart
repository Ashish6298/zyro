import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/tab_manager.dart';
import '../controllers/website_vault_controller.dart';
import '../models/website_vault_type.dart';
import '../widgets/save_to_vault_dialog.dart';
import '../widgets/vault_empty_state.dart';
import '../widgets/website_vault_domain_card.dart';
import 'website_vault_details_screen.dart';

class WebsiteVaultScreen extends StatefulWidget {
  const WebsiteVaultScreen({super.key});

  @override
  State<WebsiteVaultScreen> createState() => _WebsiteVaultScreenState();
}

class _WebsiteVaultScreenState extends State<WebsiteVaultScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Website Vault opened');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Website Vault',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Keep everything important from every website in one secure place.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Save current page',
            icon: const Icon(LucideIcons.bookmarkPlus),
            onPressed: () => _saveCurrentPage(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _confirmClearAll(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear all vault')),
            ],
          ),
        ],
      ),
      floatingActionButton: _GradientVaultFab(
        onPressed: () => _addManual(context),
      ),
      body: Consumer<WebsiteVaultController>(
        builder: (context, vault, child) {
          final summaries = vault.domainSummaries;
          final stats = _VaultStats.from(vault.items, summaries);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
            children: [
              _VaultDashboardCard(stats: stats),
              const SizedBox(height: 14),
              _SearchAndSort(
                controller: _search,
                sortMode: vault.sortMode,
                onSearch: vault.setSearchQuery,
                onSort: vault.setSortMode,
              ),
              const SizedBox(height: 16),
              if (vault.loading)
                const _VaultSkeletonList()
              else if (summaries.isEmpty)
                const VaultEmptyState(
                  onboarding: true,
                  message:
                      'Save webpages, screenshots, PDFs, downloads, invoices, receipts, links, and notes. Zyro organizes everything by website for easy retrieval.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summaries.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 260 + index * 40),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: WebsiteVaultDomainCard(
                        summary: summary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WebsiteVaultDetailsScreen(
                                domain: summary.domain,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveCurrentPage(BuildContext context) async {
    final tab = context.read<TabManager>().currentTab;
    if (tab == null) return;
    final result = await showDialog<SaveToVaultResult>(
      context: context,
      builder: (_) => SaveToVaultDialog(
        initialTitle: tab.title ?? 'Website page',
        initialUrl: tab.url,
        initialType: WebsiteVaultType.page,
      ),
    );
    if (result == null || !context.mounted) return;
    final item = await context.read<WebsiteVaultController>().saveCurrentPage(
      url: result.sourceUrl.isNotEmpty ? result.sourceUrl : tab.url,
      title: result.title,
      type: result.type,
      noteText: result.noteText,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item == null ? 'Unable to save this page' : 'Saved to Website Vault',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addManual(BuildContext context) async {
    final result = await showDialog<SaveToVaultResult>(
      context: context,
      builder: (_) => const SaveToVaultDialog(
        initialTitle: '',
        initialUrl: '',
        initialType: WebsiteVaultType.note,
      ),
    );
    if (result == null || !context.mounted) return;
    await context.read<WebsiteVaultController>().addManualItem(
      domainOrUrl: result.domainOrUrl,
      title: result.title,
      type: result.type,
      sourceUrl: result.sourceUrl,
      noteText: result.noteText,
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all vault entries?'),
        content: const Text(
          'This removes only Website Vault metadata. Browser data and local files are not deleted.',
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
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<WebsiteVaultController>().clearAll();
    }
  }
}

class _SearchAndSort extends StatelessWidget {
  final TextEditingController controller;
  final WebsiteVaultSortMode sortMode;
  final ValueChanged<String> onSearch;
  final ValueChanged<WebsiteVaultSortMode> onSort;

  const _SearchAndSort({
    required this.controller,
    required this.sortMode,
    required this.onSearch,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _AnimatedSearchShell(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onSearch,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(LucideIcons.x, size: 17),
                        onPressed: () {
                          controller.clear();
                          onSearch('');
                        },
                      ),
                hintText:
                    'Search websites, screenshots, PDFs, notes, downloads, receipts...',
                hintStyle: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
          PopupMenuButton<WebsiteVaultSortMode>(
            tooltip: 'Sort',
            icon: const Icon(LucideIcons.arrowUpDown, size: 18),
            onSelected: onSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: WebsiteVaultSortMode.recentlyUpdated,
                child: Text('Recently Updated'),
              ),
              PopupMenuItem(
                value: WebsiteVaultSortMode.mostItems,
                child: Text('Most Items'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VaultDashboardCard extends StatelessWidget {
  final _VaultStats stats;

  const _VaultDashboardCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.16),
            theme.cardColor,
            theme.colorScheme.tertiary.withValues(alpha: isDark ? 0.12 : 0.07),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.13),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  LucideIcons.shieldCheck,
                  color: theme.colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local-first vault',
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'All vault data is stored locally on your device and organized by website.',
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.56,
                        ),
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.55,
            children: [
              _StatPill(
                label: 'Websites',
                value: stats.websiteCount.toString(),
                icon: LucideIcons.globe2,
              ),
              _StatPill(
                label: 'Items',
                value: stats.itemCount.toString(),
                icon: LucideIcons.layers,
              ),
              _StatPill(
                label: 'Storage',
                value: stats.storageLabel,
                icon: LucideIcons.hardDrive,
              ),
              _StatPill(
                label: 'Recent',
                value: stats.recentLabel,
                icon: LucideIcons.clock3,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
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

class _AnimatedSearchShell extends StatefulWidget {
  final Widget child;

  const _AnimatedSearchShell({required this.child});

  @override
  State<_AnimatedSearchShell> createState() => _AnimatedSearchShellState();
}

class _AnimatedSearchShellState extends State<_AnimatedSearchShell> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(_focused ? 22 : 18),
          border: Border.all(
            color: _focused
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: (_focused ? theme.colorScheme.primary : Colors.black)
                  .withValues(alpha: _focused ? 0.12 : 0.04),
              blurRadius: _focused ? 20 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _GradientVaultFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _GradientVaultFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [theme.colorScheme.tertiary, theme.colorScheme.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.archive, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Text(
                'Save to Vault',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultSkeletonList extends StatelessWidget {
  const _VaultSkeletonList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.35, end: 0.8),
          duration: Duration(milliseconds: 650 + index * 90),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              height: 118,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: value),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.18),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _VaultStats {
  final int websiteCount;
  final int itemCount;
  final String storageLabel;
  final String recentLabel;

  const _VaultStats({
    required this.websiteCount,
    required this.itemCount,
    required this.storageLabel,
    required this.recentLabel,
  });

  factory _VaultStats.from(List<dynamic> items, List<dynamic> summaries) {
    var storage = 0;
    DateTime? latest;
    for (final item in items) {
      final size = item.fileSize;
      if (size is int) storage += size;
      final updatedAt = item.updatedAt;
      if (updatedAt is DateTime &&
          (latest == null || updatedAt.isAfter(latest))) {
        latest = updatedAt;
      }
    }
    return _VaultStats(
      websiteCount: summaries.length,
      itemCount: items.length,
      storageLabel: _formatBytes(storage),
      recentLabel: latest == null ? 'None' : _relativeDate(latest),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _relativeDate(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${value.day}/${value.month}/${value.year}';
  }
}
