import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../dev_tools_controller.dart';
import 'elements_tab.dart';
import 'console_tab.dart';
import 'network_tab.dart';
import 'storage_tab.dart';
import 'resources_tab.dart';
import 'info_tab.dart';

class DevToolsPanel extends StatefulWidget {
  final InAppWebViewController webViewController;

  const DevToolsPanel({
    super.key,
    required this.webViewController,
  });

  @override
  State<DevToolsPanel> createState() => _DevToolsPanelState();
}

class _DevToolsPanelState extends State<DevToolsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle and Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(isDark ? 0.08 : 0.12),
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.code, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'DEV TOOLS',
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () {
                            context.read<DevToolsController>().clearAll();
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Custom TabBar
          Container(
            color: theme.colorScheme.onSurface.withOpacity(0.01),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
              labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'ELEMENTS'),
                Tab(text: 'CONSOLE'),
                Tab(text: 'NETWORK'),
                Tab(text: 'STORAGE'),
                Tab(text: 'RESOURCES'),
                Tab(text: 'INFO'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ElementsTab(webViewController: widget.webViewController),
                ConsoleTab(webViewController: widget.webViewController),
                NetworkTab(webViewController: widget.webViewController),
                StorageTab(webViewController: widget.webViewController),
                ResourcesTab(webViewController: widget.webViewController),
                InfoTab(webViewController: widget.webViewController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
