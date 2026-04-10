import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/tab_manager.dart';
import '../../core/webview_wrapper.dart';
import '../../engine/script_engine.dart';
import '../widgets/cyber_menu.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import 'tab_switcher.dart';

class BrowserMainScreen extends StatefulWidget {
  const BrowserMainScreen({super.key});

  @override
  State<BrowserMainScreen> createState() => _BrowserMainScreenState();
}

class _BrowserMainScreenState extends State<BrowserMainScreen> {
  final ScriptEngine _scriptEngine = ScriptEngine();

  void _showCyberMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CyberMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabManager>(
      builder: (context, tabManager, child) {
        final currentTab = tabManager.currentTab;

        if (currentTab == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                GlassAppBar(tab: currentTab),
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
}
