import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../dev_tools_controller.dart';
import '../dev_tools_service.dart';

class ElementsTab extends StatelessWidget {
  final InAppWebViewController webViewController;

  const ElementsTab({
    super.key,
    required this.webViewController,
  });

  void _showNotification(BuildContext context, String message, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: theme.colorScheme.primary,
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
    final devTools = context.watch<DevToolsController>();
    final element = devTools.selectedElement;

    if (element == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.mousePointer, size: 40, color: theme.colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(
                'No Element Selected',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Long-press any link or element and choose "Inspect" to inspect its properties here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Highlight & Copy Toolbar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(LucideIcons.eye, size: 16),
                label: Text('Highlight Element', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (element.selector.isNotEmpty) {
                    await webViewController.evaluateJavascript(
                      source: "${DevToolsService.highlightScript}('${element.selector.replaceAll("'", "\\'")}');"
                    );
                    _showNotification(context, 'Element highlighted on webpage', theme);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.copy, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: element.selector));
                _showNotification(context, 'CSS selector copied', theme);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Node Title Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '<${element.tagName}>',
                    style: GoogleFonts.firaCode(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (element.id.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '#${element.id}',
                      style: GoogleFonts.firaCode(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (element.className.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '.${element.className.split(' ').join('.')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaCode(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ]
                ],
              ),
              if (element.textContent.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '"${element.textContent.trim()}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Expandable Sections
        _buildSection(
          theme,
          title: 'Selector Path',
          child: SelectableText(
            element.selector,
            style: GoogleFonts.firaCode(fontSize: 11, color: theme.colorScheme.onSurface),
          ),
        ),
        
        _buildSection(
          theme,
          title: 'HTML Attributes',
          child: element.attributes.isEmpty
              ? Text('No attributes found', style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)))
              : Column(
                  children: element.attributes.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}: ',
                          style: GoogleFonts.firaCode(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Expanded(
                          child: SelectableText(
                            '"${entry.value}"',
                            style: GoogleFonts.firaCode(color: theme.colorScheme.onSurface, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
        ),

        _buildSection(
          theme,
          title: 'Computed Styles',
          child: element.styles.isEmpty
              ? Text('No styles found', style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)))
              : Column(
                  children: element.styles.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${entry.key}: ',
                          style: GoogleFonts.firaCode(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Expanded(
                          child: SelectableText(
                            entry.value,
                            style: GoogleFonts.firaCode(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
        ),

        _buildSection(
          theme,
          title: 'Parent Hierarchy',
          child: element.parentHierarchy.isEmpty
              ? Text('No parent hierarchy', style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: element.parentHierarchy.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(LucideIcons.chevronRight, size: 12, color: theme.colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p,
                              style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: idx == 0 ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        _buildSection(
          theme,
          title: 'Outer HTML',
          trailing: IconButton(
            icon: const Icon(LucideIcons.copy, size: 14),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: element.outerHTML));
              _showNotification(context, 'HTML copied', theme);
            },
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxHeight: 180),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SelectableText(
                element.outerHTML,
                style: GoogleFonts.firaCode(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(theme.brightness == Brightness.dark ? 0.05 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
