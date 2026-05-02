import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/browser_data_manager.dart';
import '../widgets/glass_container.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'DOWNLOADS',
          style: GoogleFonts.shareTechMono(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.white24),
            onPressed: () => context.read<BrowserDataManager>().clearDownloads(),
          ),
        ],
      ),
      body: Consumer<BrowserDataManager>(
        builder: (context, dataManager, child) {
          final downloads = dataManager.downloads;

          if (downloads.isEmpty) {
            return Center(
              child: Text(
                'NO DOWNLOADS ACTIVE',
                style: GoogleFonts.shareTechMono(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final url = downloads[index];
              final fileName = url.split('/').last;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 16,
                  opacity: 0.05,
                  child: ListTile(
                    leading: const Icon(LucideIcons.file, color: Colors.cyanAccent, size: 20),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
                    ),
                    trailing: const CircularProgressIndicator(
                      value: 1.0, // Indeterminate or finished for now
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
