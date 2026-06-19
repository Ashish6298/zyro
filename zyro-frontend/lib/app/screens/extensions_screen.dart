import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/extension_manager.dart';
import '../../core/models/extension_model.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXTENSIONS',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Manage browser plug-ins',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, isDark),
          Expanded(
            child: Consumer<ExtensionManager>(
              builder: (context, manager, child) {
                final installed = manager.installedExtensions
                    .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();
                final available = manager.availableExtensions
                    .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (installed.isNotEmpty) ...[
                      _buildSectionHeader(theme, 'INSTALLED'),
                      ...installed.map((e) => ExtensionCard(
                            extension: e,
                            manager: manager,
                            isInstalled: true,
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (available.isNotEmpty) ...[
                      _buildSectionHeader(theme, 'AVAILABLE'),
                      ...available.map((e) => ExtensionCard(
                            extension: e,
                            manager: manager,
                            isInstalled: false,
                          )),
                    ],
                    if (installed.isEmpty && available.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 64),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.04),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.puzzle,
                                  size: 40,
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No extensions found',
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try refining your search keyword.',
                                style: GoogleFonts.outfit(
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? theme.dividerColor.withOpacity(0.06) : theme.dividerColor.withOpacity(0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search extensions...',
            hintStyle: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
            prefixIcon: Icon(LucideIcons.search, color: theme.colorScheme.primary, size: 18),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: theme.colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

class ExtensionCard extends StatefulWidget {
  final ExtensionModel extension;
  final ExtensionManager manager;
  final bool isInstalled;

  const ExtensionCard({
    super.key,
    required this.extension,
    required this.manager,
    required this.isInstalled,
  });

  @override
  State<ExtensionCard> createState() => _ExtensionCardState();
}

class _ExtensionCardState extends State<ExtensionCard> {
  double _scale = 1.0;

  void _showDeleteConfirmation(BuildContext context, ExtensionModel extension) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Remove ${extension.name}?',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'This extension will be moved back to the available list and can be installed again later.',
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.manager.uninstallExtension(extension.id);
            },
            child: Text(
              'REMOVE',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final extension = widget.extension;

    return GestureDetector(
      onTapDown: widget.isInstalled ? null : (_) => setState(() => _scale = 0.98),
      onTapUp: widget.isInstalled ? null : (_) {
        setState(() => _scale = 1.0);
        widget.manager.installExtension(extension);
      },
      onTapCancel: widget.isInstalled ? null : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? theme.dividerColor.withOpacity(0.06) : theme.dividerColor.withOpacity(0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  extension.icon,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extension.name,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extension.description,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action Switch or Download Icon
              Align(
                alignment: Alignment.centerRight,
                child: widget.isInstalled
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (extension.id != 'ad_blocker_downloader') ...[
                            IconButton(
                              icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error.withOpacity(0.85), size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.error.withOpacity(0.08),
                                padding: const EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _showDeleteConfirmation(context, extension),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Switch(
                            value: extension.isEnabled,
                            onChanged: (_) => widget.manager.toggleExtension(extension.id),
                            activeColor: theme.colorScheme.primary,
                            activeTrackColor: theme.colorScheme.primary.withOpacity(0.2),
                            inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.4),
                            inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.downloadCloud,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
