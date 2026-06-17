import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/extension_manager.dart';
import '../../core/models/extension_model.dart';
import '../widgets/glass_container.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'EXTENSIONS',
          style: GoogleFonts.shareTechMono(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (installed.isNotEmpty) ...[
                      _buildSectionHeader('INSTALLED'),
                      ...installed.map((e) => _buildExtensionTile(e, manager, isInstalled: true)),
                      const SizedBox(height: 24),
                    ],
                    if (available.isNotEmpty) ...[
                      _buildSectionHeader('AVAILABLE'),
                      ...available.map((e) => _buildExtensionTile(e, manager, isInstalled: false)),
                    ],
                    if (installed.isEmpty && available.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 64),
                          child: Text(
                            'NO EXTENSIONS FOUND',
                            style: GoogleFonts.shareTechMono(color: Colors.white24),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: 12,
        opacity: 0.05,
        child: TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'SEARCH EXTENSIONS...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12),
            prefixIcon: const Icon(LucideIcons.search, color: Colors.cyanAccent, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.shareTechMono(
          color: Colors.cyanAccent.withOpacity(0.5),
          fontSize: 12,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildExtensionTile(ExtensionModel extension, ExtensionManager manager, {required bool isInstalled}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 16,
        opacity: 0.05,
        child: ListTile(
          leading: Icon(extension.icon, color: Colors.cyanAccent, size: 24),
          title: Text(
            extension.name,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            extension.description,
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
          ),
          trailing: isInstalled
              ? Switch(
                  value: extension.isEnabled,
                  onChanged: (_) => manager.toggleExtension(extension.id),
                  activeColor: Colors.cyanAccent,
                )
              : IconButton(
                  icon: const Icon(LucideIcons.downloadCloud, color: Colors.cyanAccent),
                  onPressed: () => manager.installExtension(extension),
                ),
        ),
      ),
    );
  }
}
