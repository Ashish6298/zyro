import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/browser_data_manager.dart';
import '../widgets/glass_container.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'BOOKMARKS',
          style: GoogleFonts.shareTechMono(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<BrowserDataManager>(
        builder: (context, dataManager, child) {
          final bookmarks = dataManager.bookmarks;

          if (bookmarks.isEmpty) {
            return Center(
              child: Text(
                'NO BOOKMARKS SAVED',
                style: GoogleFonts.shareTechMono(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final item = bookmarks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 16,
                  opacity: 0.05,
                  child: ListTile(
                    leading: const Icon(LucideIcons.bookmark, color: Colors.cyanAccent, size: 20),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash, color: Colors.white24, size: 18),
                      onPressed: () => dataManager.toggleBookmark(item.url, item.title),
                    ),
                    onTap: () {
                      Navigator.pop(context, item.url);
                    },
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
