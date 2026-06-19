import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../dev_tools_controller.dart';
import '../dev_tools_models.dart';

class NetworkTab extends StatefulWidget {
  final InAppWebViewController webViewController;

  const NetworkTab({
    super.key,
    required this.webViewController,
  });

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final devTools = context.watch<DevToolsController>();
    
    final filteredLogs = devTools.networkLogs.where((log) {
      if (_filter.isEmpty) return true;
      return log.url.toLowerCase().contains(_filter.toLowerCase()) ||
          log.method.toLowerCase().contains(_filter.toLowerCase()) ||
          log.resourceType.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.1)),
                  ),
                  child: TextField(
                    style: GoogleFonts.outfit(fontSize: 13, color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Filter network requests...',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      prefixIcon: Icon(LucideIcons.search, size: 16, color: theme.colorScheme.primary),
                      prefixIconConstraints: const BoxConstraints(minWidth: 28, maxHeight: 18),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _filter = val;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () {
                  // Trigger a reload to catch new logs
                  widget.webViewController.reload();
                },
              ),
            ],
          ),
        ),

        // Network Logs List
        Expanded(
          child: filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.activity, size: 40, color: theme.colorScheme.primary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No Network Requests Logged',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reload the page to capture network requests.',
                        style: GoogleFonts.outfit(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final isError = log.statusCode != null && (log.statusCode! >= 400 || log.statusCode == 0);
                    
                    return Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isError 
                              ? theme.colorScheme.error.withOpacity(0.2) 
                              : theme.dividerColor.withOpacity(isDark ? 0.05 : 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isError ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.method,
                                  style: GoogleFonts.outfit(
                                    color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.resourceType.toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: theme.colorScheme.secondary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (log.statusCode != null)
                                Text(
                                  log.statusCode.toString(),
                                  style: GoogleFonts.outfit(
                                    color: isError ? theme.colorScheme.error : Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            log.url,
                            style: GoogleFonts.firaCode(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
