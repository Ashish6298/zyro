import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/browser_data_manager.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _getGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'TODAY';
    } else if (targetDate == yesterday) {
      return 'YESTERDAY';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

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
              'HISTORY',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Your browsing timeline',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.trash2, color: theme.colorScheme.error.withOpacity(0.8), size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withOpacity(0.06),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () => context.read<BrowserDataManager>().clearHistory(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<BrowserDataManager>(
        builder: (context, dataManager, child) {
          final history = dataManager.history.reversed.toList();

          if (history.isEmpty) {
            return Center(
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
                      LucideIcons.history,
                      size: 40,
                      color: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history found',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your visited sites will appear here.',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }

          // Build a flat list with grouped day headers
          final List<dynamic> listItems = [];
          DateTime? lastDate;
          for (final item in history) {
            if (lastDate == null || !_isSameDay(lastDate, item.timestamp)) {
              lastDate = item.timestamp;
              listItems.add(_getGroupHeader(lastDate));
            }
            listItems.add(item);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: listItems.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = listItems[index];

              if (item is String) {
                // Return Section Header
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                          color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.15),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Return History Card
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HistoryCard(
                  item: item,
                  onTap: () {
                    Navigator.pop(context, item.url);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class HistoryCard extends StatefulWidget {
  final dynamic item;
  final VoidCallback onTap;

  const HistoryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    String domainLetter = '';
    try {
      final uri = Uri.parse(item.url);
      final host = uri.host.replaceAll('www.', '');
      if (host.isNotEmpty) {
        domainLetter = host[0].toUpperCase();
      }
    } catch (_) {
      domainLetter = 'W';
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            children: [
              // Domain Avatars circle
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    domainLetter,
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Content Text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Untitled Page' : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Time and navigation details
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
