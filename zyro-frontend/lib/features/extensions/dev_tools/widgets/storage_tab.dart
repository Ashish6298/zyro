import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../dev_tools_service.dart';
import '../dev_tools_models.dart';

class StorageTab extends StatefulWidget {
  final InAppWebViewController webViewController;

  const StorageTab({
    super.key,
    required this.webViewController,
  });

  @override
  State<StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<StorageTab> with SingleTickerProviderStateMixin {
  late TabController _storageTypeController;
  List<StorageItem> _cookies = [];
  List<StorageItem> _localStorage = [];
  List<StorageItem> _sessionStorage = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _storageTypeController = TabController(length: 3, vsync: this);
    _loadStorageData();
  }

  @override
  void dispose() {
    _storageTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dynamic result = await widget.webViewController.evaluateJavascript(
        source: DevToolsService.getStorageScript,
      );

      if (result != null && result is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(result);
        
        final cookiesList = data['cookies'] as List? ?? [];
        final localList = data['localStorage'] as List? ?? [];
        final sessionList = data['sessionStorage'] as List? ?? [];

        setState(() {
          _cookies = cookiesList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return StorageItem(key: map['key']?.toString() ?? '', value: map['value']?.toString() ?? '', type: 'cookie');
          }).toList();

          _localStorage = localList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return StorageItem(key: map['key']?.toString() ?? '', value: map['value']?.toString() ?? '', type: 'localStorage');
          }).toList();

          _sessionStorage = sessionList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return StorageItem(key: map['key']?.toString() ?? '', value: map['value']?.toString() ?? '', type: 'sessionStorage');
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading storage data: $e");
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

    return Column(
      children: [
        // Storage type selector
        Container(
          color: theme.colorScheme.onSurface.withOpacity(0.02),
          child: TabBar(
            controller: _storageTypeController,
            indicatorColor: theme.colorScheme.secondary,
            indicatorWeight: 2,
            labelColor: theme.colorScheme.secondary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
            labelStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'COOKIES'),
              Tab(text: 'LOCAL STORAGE'),
              Tab(text: 'SESSION STORAGE'),
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
                'STORAGE VIEWER',
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
                onPressed: _loadStorageData,
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _storageTypeController,
                  children: [
                    _buildStorageList(_cookies, theme, isDark, 'No cookies found'),
                    _buildStorageList(_localStorage, theme, isDark, 'LocalStorage is empty'),
                    _buildStorageList(_sessionStorage, theme, isDark, 'SessionStorage is empty'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStorageList(List<StorageItem> items, ThemeData theme, bool isDark, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.database, size: 36, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.key,
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 12),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSurface.withOpacity(0.03),
                      padding: const EdgeInsets.all(6),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.value));
                      _showNotification('Value copied to clipboard');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  item.value,
                  style: GoogleFonts.firaCode(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
