import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/browser_data_manager.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.shareTechMono(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('PRIVACY'),
          _buildSettingTile(
            context,
            icon: LucideIcons.history,
            title: 'Clear History',
            onTap: () {
              context.read<BrowserDataManager>().clearHistory();
              _showDone(context);
            },
          ),
          _buildSettingTile(
            context,
            icon: LucideIcons.bookmark,
            title: 'Clear Bookmarks',
            onTap: () {
              context.read<BrowserDataManager>().clearBookmarks();
               _showDone(context);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('UI'),
          _buildSettingTile(
            context,
            icon: LucideIcons.palette,
            title: 'Cyberpunk Theme',
            subtitle: 'Always Active',
            onTap: null,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('ABOUT'),
          _buildSettingTile(
            context,
            icon: LucideIcons.info,
            title: 'Zyro Browser',
            subtitle: 'Version 1.0.0',
            onTap: null,
          ),
        ],
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

  Widget _buildSettingTile(BuildContext context, {required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 16,
        opacity: 0.05,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
          title: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle != null ? Text(
            subtitle,
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11),
          ) : null,
          trailing: onTap != null ? const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 18) : null,
        ),
      ),
    );
  }

  void _showDone(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Action Completed'), backgroundColor: Colors.cyanAccent),
    );
  }
}
