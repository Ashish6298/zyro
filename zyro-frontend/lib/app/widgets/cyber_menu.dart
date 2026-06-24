import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/tab_manager.dart';
import '../../core/browser_data_manager.dart';
import '../screens/history_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../../features/download_library/screens/downloads_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../screens/extensions_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../features/screenshot_pro/screens/screenshot_pro_sheet.dart';

class CyberMenu extends StatelessWidget {
  const CyberMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManager>(context);
    final currentTab = tabManager.currentTab;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.82,
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 48,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.54 : 0.08),
              blurRadius: 24,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent visual header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ZYRO BROWSER',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.primary,
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    LucideIcons.chevronRight,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(
                      0.04,
                    ),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Grid section
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.0,
                physics: const BouncingScrollPhysics(),
                children: [
                  MenuCard(
                    icon:
                        context.watch<BrowserDataManager>().isBookmarked(
                          currentTab?.url ?? '',
                        )
                        ? LucideIcons.star
                        : LucideIcons.bookmark,
                    label:
                        context.watch<BrowserDataManager>().isBookmarked(
                          currentTab?.url ?? '',
                        )
                        ? 'SAVED'
                        : 'BOOKMARK',
                    description: 'Save page to library',
                    isActive: context.watch<BrowserDataManager>().isBookmarked(
                      currentTab?.url ?? '',
                    ),
                    onPressed: () {
                      if (currentTab != null) {
                        context.read<BrowserDataManager>().toggleBookmark(
                          currentTab.url,
                          currentTab.title ?? 'New Tab',
                        );
                      }
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.plus,
                    label: 'NEW TAB',
                    description: 'Open clean slate',
                    isImportant: true,
                    onPressed: () {
                      tabManager.addNewTab();
                      Navigator.pop(context);
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.eyeOff,
                    label: 'INCOGNITO MODE',
                    description: tabManager.isGlobalIncognito
                        ? 'Private browsing active'
                        : 'Private browsing off',
                    isActive: tabManager.isGlobalIncognito,
                    onPressed: () {
                      final isEnabling = !tabManager.isGlobalIncognito;
                      tabManager.setGlobalIncognito(isEnabling);
                      Navigator.pop(context);

                      if (isEnabling) {
                        _showIncognitoExplanationDialog(context);
                      }
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.refreshCw,
                    label: 'REFRESH',
                    description: 'Reload current page',
                    onPressed: () {
                      currentTab?.controller?.reload();
                      Navigator.pop(context);
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.share2,
                    label: 'SHARE',
                    description: 'Send page link',
                    onPressed: () {
                      if (currentTab != null) {
                        Share.share(currentTab.url);
                      }
                      Navigator.pop(context);
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.history,
                    label: 'HISTORY',
                    description: 'Recently visited',
                    onPressed: () async {
                      final url = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                      if (url != null && url is String) {
                        currentTab?.controller?.loadUrl(
                          urlRequest: URLRequest(url: WebUri(url)),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.bookmark,
                    label: 'BOOKMARKS',
                    description: 'View saved sites',
                    onPressed: () async {
                      final url = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookmarksScreen(),
                        ),
                      );
                      if (url != null && url is String) {
                        currentTab?.controller?.loadUrl(
                          urlRequest: URLRequest(url: WebUri(url)),
                        );
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.monitor,
                    label: 'DESKTOP',
                    description: 'Request PC site',
                    isActive: currentTab?.isDesktopMode ?? false,
                    onPressed: () {
                      tabManager.toggleDesktopMode(tabManager.currentIndex);
                      Navigator.pop(context);
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.search,
                    label: 'FIND IN PAGE',
                    description: 'Locate site terms',
                    onPressed: () {
                      Navigator.pop(context);
                      Provider.of<TabManager>(
                        context,
                        listen: false,
                      ).toggleFindInPage();
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.camera,
                    label: 'SCREENSHOT PRO',
                    description: 'Full page capture',
                    onPressed: () {
                      if (currentTab == null) return;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScreenshotProSheet(tab: currentTab),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.download,
                    label: 'DOWNLOADS',
                    description: 'Manage files',
                    isImportant: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DownloadsScreen(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.settings,
                    label: 'SETTINGS',
                    description: 'App preferences',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: LucideIcons.puzzle,
                    label: 'EXTENSIONS',
                    description: 'Manage add-ons',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExtensionsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isImportant;

  const MenuCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.onPressed,
    this.isActive = false,
    this.isImportant = false,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

    Color cardColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    Color descColor;

    if (widget.isActive) {
      cardColor = activeColor.withOpacity(isDark ? 0.15 : 0.08);
      borderColor = activeColor;
      iconColor = activeColor;
      textColor = activeColor;
      descColor = activeColor.withOpacity(0.7);
    } else {
      cardColor = isDark ? theme.cardColor.withOpacity(0.5) : theme.cardColor;
      borderColor = isDark
          ? theme.dividerColor.withOpacity(0.1)
          : theme.dividerColor.withOpacity(0.5);
      iconColor = theme.colorScheme.onSurface;
      textColor = theme.colorScheme.onSurface.withOpacity(0.9);
      descColor = theme.colorScheme.onSurface.withOpacity(0.4);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.15)
                    : Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (widget.isImportant && !widget.isActive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isActive
                            ? activeColor.withOpacity(0.1)
                            : theme.colorScheme.onSurface.withOpacity(0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: descColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
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

void _showIncognitoExplanationDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.eyeOff, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Incognito Mode Enabled',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have switched to a private browsing session. Zyro Browser will protect your privacy with the following rules:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint(
              theme,
              'Browsing history and search history will not be saved.',
            ),
            _buildBulletPoint(
              theme,
              'Cookies and site storage are cleared when closed.',
            ),
            _buildBulletPoint(
              theme,
              'Form data and inputs will not be remembered.',
            ),
            _buildBulletPoint(
              theme,
              'Bookmarks and downloads you manually save will still remain.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildBulletPoint(ThemeData theme, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.check, size: 14, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    ),
  );
}
