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
import '../screens/downloads_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/extensions_screen.dart';
import 'glass_container.dart';

class CyberMenu extends StatelessWidget {
  const CyberMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManager>(context);
    final currentTab = tabManager.currentTab;

    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B), // Slightly lighter for the drawer depth
          borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(-5, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MENU',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.cyanAccent,
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.chevronRight, color: Colors.cyanAccent, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Expanded(
              child: GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.0,
                children: [
                   _buildMenuCard(
                    context,
                    icon: context.watch<BrowserDataManager>().isBookmarked(currentTab?.url ?? '') 
                        ? LucideIcons.star 
                        : LucideIcons.bookmark,
                    label: context.watch<BrowserDataManager>().isBookmarked(currentTab?.url ?? '')
                        ? 'SAVED'
                        : 'BOOKMARK',
                    isActive: context.watch<BrowserDataManager>().isBookmarked(currentTab?.url ?? ''),
                    onPressed: () {
                      if (currentTab != null) {
                        context.read<BrowserDataManager>().toggleBookmark(currentTab.url, currentTab.title ?? 'New Tab');
                      }
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.plus,
                    label: 'NEW_TAB',
                    onPressed: () {
                      tabManager.addNewTab();
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.refreshCw,
                    label: 'REFRESH',
                    onPressed: () {
                      currentTab?.controller?.reload();
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.share2,
                    label: 'SHARE',
                    onPressed: () {
                      if (currentTab != null) {
                        Share.share(currentTab.url);
                      }
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.history,
                    label: 'HISTORY',
                    onPressed: () async {
                      final url = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                      if (url != null && url is String) {
                        currentTab?.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.bookmark,
                    label: 'BOOKMARKS',
                    onPressed: () async {
                       final url = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                      );
                      if (url != null && url is String) {
                        currentTab?.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.monitor,
                    label: 'DESKTOP',
                    isActive: currentTab?.isDesktopMode ?? false,
                    onPressed: () {
                      tabManager.toggleDesktopMode(tabManager.currentIndex);
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.search,
                    label: 'FIND_IN',
                    onPressed: () {
                      Navigator.pop(context);
                      // Trigger Find in Page UI in BrowserMainScreen via a callback or state
                      // We'll handle this in BrowserMainScreen by adding a 'isFinding' state
                      Provider.of<TabManager>(context, listen: false).toggleFindInPage();
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.download,
                    label: 'DOWNLOADS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DownloadsScreen()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.settings,
                    label: 'SETTINGS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: LucideIcons.puzzle,
                    label: 'EXTENSIONS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExtensionsScreen()),
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

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        borderRadius: 20,
        opacity: isActive ? 0.25 : 0.08,
        color: isActive ? Colors.cyanAccent : const Color(0xFF334155),
        border: Border.all(
          color: isActive ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.cyanAccent : Colors.white70,
              size: 28,
              shadows: isActive ? [
                Shadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 15)
              ] : null,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: isActive ? Colors.cyanAccent : Colors.white38,
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
