import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/tab_manager.dart';
import '../../core/browser_data_manager.dart';
import '../../core/webview_wrapper.dart';
import '../../engine/script_engine.dart';
import '../widgets/cyber_menu.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import 'tab_switcher.dart';

import '../../features/video_downloader/widgets/floating_download_button.dart';

class BrowserMainScreen extends StatefulWidget {
  const BrowserMainScreen({super.key});

  @override
  State<BrowserMainScreen> createState() => _BrowserMainScreenState();
}

class _BrowserMainScreenState extends State<BrowserMainScreen> {
  final ScriptEngine _scriptEngine = ScriptEngine();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showCyberMenu(BuildContext context) {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TabManager, BrowserDataManager>(
      builder: (context, tabManager, dataManager, child) {
        // Listen for finished downloads
        if (dataManager.lastFinishedDownload != null) {
          final item = dataManager.lastFinishedDownload!;
          dataManager.lastFinishedDownload = null; // Clear to prevent multiple notifications
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOWNLOAD COMPLETE',
                            style: GoogleFonts.shareTechMono(color: Colors.greenAccent, fontSize: 10, letterSpacing: 2),
                          ),
                          Text(
                            '${item.title} saved to device.',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0F172A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          });
        }

        final currentTab = tabManager.currentTab;

        if (currentTab == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          key: _scaffoldKey,
          endDrawer: const CyberMenu(),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    GlassAppBar(tab: currentTab),
                    if (tabManager.isFindingInPage) _buildFindBar(tabManager),
                    Expanded(
                      child: IndexedStack(
                        index: tabManager.currentIndex,
                        children: tabManager.tabs.map((tab) {
                          return WebViewWrapper(
                            key: ValueKey(tab.id),
                            tab: tab,
                            scriptEngine: _scriptEngine,
                          );
                        }).toList(),
                      ),
                    ),
                    _buildBottomNav(tabManager),
                  ],
                ),
                const FloatingDownloadButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(TabManager tabManager) {
    final currentTab = tabManager.currentTab!;
    
    return Container(
      padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24, top: 4),
      child: GlassContainer(
        borderRadius: 24,
        opacity: 0.1,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(
                icon: LucideIcons.chevronLeft,
                onPressed: () {
                  currentTab.controller?.goBack();
                },
              ),
              _buildNavButton(
                icon: LucideIcons.chevronRight,
                onPressed: () {
                  currentTab.controller?.goForward();
                },
              ),
              _buildCenterButton(tabManager),
              _buildNavButton(
                icon: LucideIcons.layers,
                badge: '${tabManager.tabs.length}',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TabSwitcherScreen()),
                  );
                },
              ),
              _buildNavButton(
                icon: LucideIcons.moreHorizontal,
                onPressed: () => _showCyberMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onPressed, String? badge}) {
    return IconButton(
      icon: badge != null 
          ? Badge(
              label: Text(badge, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
              backgroundColor: Colors.cyanAccent,
              child: Icon(icon, color: Colors.white60, size: 20),
            )
          : Icon(icon, color: Colors.white60, size: 20),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildCenterButton(TabManager tabManager) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        tabManager.addNewTab();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.cyanAccent, Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(LucideIcons.plus, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildFindBar(TabManager tabManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: GlassContainer(
        borderRadius: 12,
        opacity: 0.1,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(LucideIcons.search, color: Colors.cyanAccent, size: 18),
            ),
            Expanded(
              child: TextField(
                autofocus: true,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'FIND IN PAGE...',
                  hintStyle: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  tabManager.currentTab?.controller?.findAllAsync(find: value);
                },
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white38, size: 18),
              onPressed: () {
                tabManager.currentTab?.controller?.clearMatches();
                tabManager.toggleFindInPage();
              },
            ),
          ],
        ),
      ),
    );
  }
}
