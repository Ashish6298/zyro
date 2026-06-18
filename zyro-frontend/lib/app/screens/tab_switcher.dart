import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/tab_manager.dart';
import '../../core/models/tab_model.dart';

class TabSwitcherScreen extends StatelessWidget {
  const TabSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVE SESSIONS',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Manage your active workspaces',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: theme.colorScheme.primary, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<TabManager>().addNewTab();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<TabManager>(
        builder: (context, tabManager, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: tabManager.tabs.length,
            itemBuilder: (context, index) {
              final tab = tabManager.tabs[index];
              final isCurrent = index == tabManager.currentIndex;

              return SessionCard(
                tab: tab,
                index: index,
                isCurrent: isCurrent,
                onTap: () {
                  HapticFeedback.selectionClick();
                  tabManager.switchTab(index);
                  Navigator.pop(context);
                },
                onClose: () => tabManager.closeTab(index),
              );
            },
          );
        },
      ),
    );
  }
}

class SessionCard extends StatefulWidget {
  final TabModel tab;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const SessionCard({
    super.key,
    required this.tab,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final tab = widget.tab;

    String domainLetter = '';
    String domainName = 'New Tab';
    try {
      if (tab.url.isNotEmpty && tab.url.startsWith('http')) {
        final uri = Uri.parse(tab.url);
        final host = uri.host.replaceAll('www.', '');
        if (host.isNotEmpty) {
          domainLetter = host[0].toUpperCase();
          domainName = host;
        }
      }
    } catch (_) {}

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isCurrent 
                  ? activeColor 
                  : (isDark ? theme.dividerColor.withOpacity(0.06) : theme.dividerColor.withOpacity(0.4)),
              width: widget.isCurrent ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isCurrent
                    ? activeColor.withOpacity(isDark ? 0.15 : 0.05)
                    : (isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02)),
                blurRadius: widget.isCurrent ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (tab.groupName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(LucideIcons.folder, size: 10, color: theme.colorScheme.secondary),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              'SESSION 0${widget.index + 1}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: widget.isCurrent ? activeColor : theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        PopupMenuButton<String>(
                          icon: Icon(
                            LucideIcons.moreVertical,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (value) {
                            if (value == 'new_tab') {
                              context.read<TabManager>().addNewTab(url: tab.url);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opened in a new tab', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  backgroundColor: theme.colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } else if (value == 'new_group') {
                              final newTab = context.read<TabManager>().openInTabGroup(url: tab.url);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opened in new tab group: ${newTab.groupName}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                  backgroundColor: theme.colorScheme.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'new_tab',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.plus, size: 14, color: theme.colorScheme.onSurface),
                                  const SizedBox(width: 8),
                                  Text('Open in New Tab', style: GoogleFonts.outfit(fontSize: 12)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'new_group',
                              child: Row(
                                children: [
                                  Icon(LucideIcons.folderPlus, size: 14, color: theme.colorScheme.onSurface),
                                  const SizedBox(width: 8),
                                  Text('Open in New Tab Group', style: GoogleFonts.outfit(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Preview Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? theme.dividerColor.withOpacity(0.04) : theme.dividerColor.withOpacity(0.2),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(widget.isCurrent ? 0.05 : 0.01),
                                  theme.colorScheme.tertiary.withOpacity(widget.isCurrent ? 0.05 : 0.01),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: widget.isCurrent 
                                  ? activeColor.withOpacity(0.06) 
                                  : theme.colorScheme.onSurface.withOpacity(0.02),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                LucideIcons.globe, 
                                size: 24, 
                                color: widget.isCurrent ? activeColor : theme.colorScheme.onSurface.withOpacity(0.15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Card Footer (Session Info)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (domainLetter.isNotEmpty) ...[
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                domainLetter,
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.primary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            domainName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.title ?? 'New Tab',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: widget.isCurrent ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
