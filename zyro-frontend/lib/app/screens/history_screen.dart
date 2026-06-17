import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/browser_data_manager.dart';
import '../widgets/glass_container.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'HISTORY',
          style: GoogleFonts.shareTechMono(
            color: Colors.cyanAccent,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            onPressed: () => context.read<BrowserDataManager>().clearHistory(),
          ),
        ],
      ),
      body: Consumer<BrowserDataManager>(
        builder: (context, dataManager, child) {
          final history = dataManager.history.reversed.toList();

          if (history.isEmpty) {
            return Center(
              child: Text(
                'NO HISTORY FOUND',
                style: GoogleFonts.shareTechMono(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 16,
                  opacity: 0.05,
                  child: ListTile(
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
                    trailing: Text(
                      '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.shareTechMono(color: Colors.cyanAccent.withOpacity(0.5), fontSize: 10),
                    ),
                    onTap: () {
                      // Navigate back to browser and load URL
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
