import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/tab_manager.dart';
import 'glass_container.dart';

class CyberMenu extends StatelessWidget {
  const CyberMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManager>(context);
    final currentTab = tabManager.currentTab;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
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
                  // Integrate share logic later
                  Navigator.pop(context);
                },
              ),
              _buildMenuCard(
                context,
                icon: LucideIcons.history,
                label: 'HISTORY',
                onPressed: () {},
              ),
              _buildMenuCard(
                context,
                icon: LucideIcons.bookmark,
                label: 'BOOKMARKS',
                onPressed: () {},
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
                onPressed: () {},
              ),
              _buildMenuCard(
                context,
                icon: LucideIcons.download,
                label: 'DOWNLOADS',
                onPressed: () {},
              ),
              _buildMenuCard(
                context,
                icon: LucideIcons.settings,
                label: 'SETTINGS',
                onPressed: () {},
              ),
            ],
          ),
        ],
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
        borderRadius: 16,
        opacity: isActive ? 0.2 : 0.05,
        color: isActive ? Colors.cyanAccent : Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.cyanAccent : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: isActive ? Colors.cyanAccent : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
