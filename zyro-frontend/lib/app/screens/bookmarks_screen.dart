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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'BOOKMARKS',
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onBackground,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
      ),
      body: Consumer<BrowserDataManager>(
        builder: (context, dataManager, child) {
          final bookmarks = dataManager.bookmarks;

          if (bookmarks.isEmpty) {
            return Center(
              child: Text(
                'NO BOOKMARKS SAVED',
                style: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.3)),
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
                  opacity: isDark ? 0.05 : 0.02,
                  child: ListTile(
                    leading: Icon(LucideIcons.bookmark, color: theme.colorScheme.primary, size: 20),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: theme.colorScheme.onBackground, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(color: theme.colorScheme.onBackground.withOpacity(0.4), fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: Icon(LucideIcons.trash, color: theme.colorScheme.onBackground.withOpacity(0.3), size: 18),
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
