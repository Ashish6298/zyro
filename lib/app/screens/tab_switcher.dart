import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/tab_manager.dart';
import '../widgets/glass_container.dart';

class TabSwitcherScreen extends StatelessWidget {
  const TabSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('ACTIVE_SESSIONS_', style: GoogleFonts.shareTechMono(color: Colors.cyanAccent)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: Colors.cyanAccent),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.read<TabManager>().addNewTab();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<TabManager>(
        builder: (context, tabManager, child) {
          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: tabManager.tabs.length,
                itemBuilder: (context, index) {
                  final tab = tabManager.tabs[index];
                  final isCurrent = index == tabManager.currentIndex;

                  return Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    margin: const EdgeInsets.only(right: 32),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        tabManager.switchTab(index);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              border: Border.all(color: isCurrent ? Colors.cyanAccent.withOpacity(0.3) : Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SESSION_0${index + 1}',
                                  style: GoogleFonts.shareTechMono(
                                    color: isCurrent ? Colors.cyanAccent : Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!isCurrent || tabManager.tabs.length > 1)
                                  GestureDetector(
                                    onTap: () => tabManager.closeTab(index),
                                    child: Icon(LucideIcons.x, size: 16, color: isCurrent ? Colors.cyanAccent : Colors.white24),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B), // Solid background to prevent floating look
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                border: Border.all(color: isCurrent ? Colors.cyanAccent.withOpacity(0.5) : Colors.white10),
                                boxShadow: isCurrent ? [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.15),
                                    blurRadius: 30,
                                    spreadRadius: -5,
                                  )
                                ] : [],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(12),
                                        image: const DecorationImage(
                                          image: NetworkImage('https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=2070&auto=format&fit=crop'),
                                          opacity: 0.1,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.globe, 
                                          size: 56, 
                                          color: isCurrent ? Colors.cyanAccent.withOpacity(0.4) : Colors.white10
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                    ),
                                    child: Text(
                                      tab.title ?? tab.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w600,
                                        color: isCurrent ? Colors.white : Colors.white60,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Manual navigation handles (floating but with background)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(LucideIcons.chevronLeft, color: Colors.white.withOpacity(0.1), size: 32),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(LucideIcons.chevronRight, color: Colors.white.withOpacity(0.1), size: 32),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
