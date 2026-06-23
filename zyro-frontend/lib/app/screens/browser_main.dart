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
import '../../features/extensions/floating_videos/floating_videos_controller.dart';
import '../../features/extensions/floating_videos/widgets/pip_video_only_view.dart';

class BrowserMainScreen extends StatefulWidget {
  const BrowserMainScreen({super.key});

  @override
  State<BrowserMainScreen> createState() => _BrowserMainScreenState();
}

class _BrowserMainScreenState extends State<BrowserMainScreen> {
  final ScriptEngine _scriptEngine = ScriptEngine();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool? _lastPipState;

  void _showCyberMenu(BuildContext context) {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final floatingCtrl = context.watch<FloatingVideosController>();
    if (floatingCtrl.renderMode == BrowserRenderMode.pipPreparing ||
        floatingCtrl.renderMode == BrowserRenderMode.pipActive) {
      print("browser_main.dart early returned PipVideoOnlyView");
      print("Normal browser Row skipped during PiP");
      return PipVideoOnlyView(scriptEngine: _scriptEngine);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isInPipMode = floatingCtrl.state == FloatingVideoState.pipActive;

    if (isInPipMode != _lastPipState) {
      _lastPipState = isInPipMode;
      if (isInPipMode) {
        print("[FLOATING VIDEO DEBUG] PiP mode entered");
        print("[FLOATING VIDEO DEBUG] normal browser UI hidden in PiP");
      } else {
        print("[FLOATING VIDEO DEBUG] PiP exited");
        print("[FLOATING VIDEO DEBUG] normal UI restored");
      }
    }

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
                    const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOWNLOAD COMPLETE',
                            style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          Text(
                            '${item.title} saved to device.',
                            style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: theme.cardColor,
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
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  children: [
                    GlassAppBar(tab: currentTab),
                    if (tabManager.isFindingInPage) _buildFindBar(tabManager, theme),
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
                    _buildBottomNav(tabManager, theme, isDark),
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

  Widget _buildBottomNav(TabManager tabManager, ThemeData theme, bool isDark) {
    final currentTab = tabManager.currentTab!;
    
    return Container(
      padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24, top: 4),
      child: GlassContainer(
        borderRadius: 24,
        opacity: isDark ? 0.1 : 0.03,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(
                theme,
                icon: LucideIcons.chevronLeft,
                onPressed: () {
                  currentTab.controller?.goBack();
                },
              ),
              _buildNavButton(
                theme,
                icon: LucideIcons.chevronRight,
                onPressed: () {
                  currentTab.controller?.goForward();
                },
              ),
              _buildCenterButton(tabManager, theme),
              _buildNavButton(
                theme,
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
                theme,
                icon: LucideIcons.moreHorizontal,
                onPressed: () => _showCyberMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(ThemeData theme, {required IconData icon, required VoidCallback onPressed, String? badge}) {
    return IconButton(
      icon: badge != null 
          ? Badge(
              label: Text(badge, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: theme.colorScheme.primary,
              child: Icon(icon, color: theme.colorScheme.onBackground.withOpacity(0.6), size: 20),
            )
          : Icon(icon, color: theme.colorScheme.onBackground.withOpacity(0.6), size: 20),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildCenterButton(TabManager tabManager, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        tabManager.addNewTab();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.tertiary, theme.colorScheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildFindBar(TabManager tabManager, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.brightness == Brightness.dark ? Colors.black26 : Colors.black12,
      child: GlassContainer(
        borderRadius: 12,
        opacity: 0.1,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(LucideIcons.search, color: theme.colorScheme.primary, size: 18),
            ),
            Expanded(
              child: TextField(
                autofocus: true,
                style: GoogleFonts.outfit(color: theme.colorScheme.onBackground, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'FIND IN PAGE...',
                  hintStyle: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.3), fontSize: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                onChanged: (value) {
                  tabManager.currentTab?.controller?.findAllAsync(find: value);
                },
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.x, color: theme.colorScheme.onBackground.withOpacity(0.4), size: 18),
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
