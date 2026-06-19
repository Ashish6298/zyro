import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../dev_tools_service.dart';
import '../dev_tools_models.dart';

class ResourcesTab extends StatefulWidget {
  final InAppWebViewController webViewController;

  const ResourcesTab({
    super.key,
    required this.webViewController,
  });

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> with SingleTickerProviderStateMixin {
  late TabController _resourceCategoryController;
  List<ResourceItem> _resources = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resourceCategoryController = TabController(length: 4, vsync: this);
    _loadResources();
  }

  @override
  void dispose() {
    _resourceCategoryController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dynamic result = await widget.webViewController.evaluateJavascript(
        source: DevToolsService.getResourcesScript,
      );

      if (result != null && result is List) {
        setState(() {
          _resources = result.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return ResourceItem(
              url: map['url']?.toString() ?? '',
              type: map['type']?.toString() ?? '',
              name: map['name']?.toString() ?? '',
            );
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading resources: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scripts = _resources.where((r) => r.type == 'script').toList();
    final stylesheets = _resources.where((r) => r.type == 'stylesheet').toList();
    final images = _resources.where((r) => r.type == 'image').toList();
    final media = _resources.where((r) => r.type == 'media').toList();

    return Column(
      children: [
        // Category selectors
        Container(
          color: theme.colorScheme.onSurface.withOpacity(0.02),
          child: TabBar(
            controller: _resourceCategoryController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
            labelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'SCRIPTS'),
              Tab(text: 'STYLESHEETS'),
              Tab(text: 'IMAGES'),
              Tab(text: 'MEDIA'),
            ],
          ),
        ),

        // Refresh Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESOURCES DISCOVERED',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.refreshCw, size: 14, color: theme.colorScheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.06),
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: _loadResources,
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _resourceCategoryController,
                  children: [
                    _buildResourceList(scripts, theme, isDark, LucideIcons.fileCode, 'No scripts detected'),
                    _buildResourceList(stylesheets, theme, isDark, LucideIcons.brush, 'No stylesheets detected'),
                    _buildResourceList(images, theme, isDark, LucideIcons.image, 'No images detected'),
                    _buildResourceList(media, theme, isDark, LucideIcons.video, 'No media files detected'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildResourceList(List<ResourceItem> items, ThemeData theme, bool isDark, IconData icon, String emptyMsg) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaCode(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.copy, size: 12),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.03),
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.url));
                  _showNotification('Resource URL copied');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
