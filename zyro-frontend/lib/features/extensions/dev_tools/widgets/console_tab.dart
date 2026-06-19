import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../dev_tools_controller.dart';
import '../dev_tools_models.dart';

class ConsoleTab extends StatefulWidget {
  final InAppWebViewController webViewController;

  const ConsoleTab({
    super.key,
    required this.webViewController,
  });

  @override
  State<ConsoleTab> createState() => _ConsoleTabState();
}

class _ConsoleTabState extends State<ConsoleTab> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _runScript() async {
    final code = _inputController.text.trim();
    if (code.isEmpty) return;

    _inputController.clear();
    final controller = context.read<DevToolsController>();

    // Add command to log
    controller.addConsoleLog('> $code', ConsoleLogType.info);

    try {
      final dynamic result = await widget.webViewController.evaluateJavascript(source: code);
      controller.addConsoleLog(result?.toString() ?? 'undefined', ConsoleLogType.log);
    } catch (e) {
      controller.addConsoleLog(e.toString(), ConsoleLogType.error);
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getLogColor(ConsoleLogType type, ThemeData theme) {
    switch (type) {
      case ConsoleLogType.error:
        return theme.colorScheme.error;
      case ConsoleLogType.warn:
        return Colors.orangeAccent;
      case ConsoleLogType.info:
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  IconData _getLogIcon(ConsoleLogType type) {
    switch (type) {
      case ConsoleLogType.error:
        return LucideIcons.alertTriangle;
      case ConsoleLogType.warn:
        return LucideIcons.alertCircle;
      case ConsoleLogType.info:
        return LucideIcons.chevronRight;
      default:
        return LucideIcons.terminal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final devTools = context.watch<DevToolsController>();
    final logs = devTools.consoleLogs;

    return Column(
      children: [
        // Console Logs list
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.terminal, size: 40, color: theme.colorScheme.primary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'Console is Empty',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JavaScript logs and errors will be logged here.',
                        style: GoogleFonts.outfit(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final color = _getLogColor(log.type, theme);
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: log.type == ConsoleLogType.error
                            ? theme.colorScheme.error.withOpacity(0.04)
                            : (log.type == ConsoleLogType.warn ? Colors.orangeAccent.withOpacity(0.04) : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_getLogIcon(log.type), size: 14, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              log.message,
                              style: GoogleFonts.firaCode(
                                fontSize: 11,
                                color: color,
                                fontWeight: log.type == ConsoleLogType.info ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                            style: GoogleFonts.outfit(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Command Input Field
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            top: 12,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withOpacity(isDark ? 0.08 : 0.15)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.1)),
                  ),
                  child: TextField(
                    controller: _inputController,
                    style: GoogleFonts.firaCode(fontSize: 12, color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Run Javascript code...',
                      hintStyle: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _runScript(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(LucideIcons.play, color: theme.colorScheme.primary, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: _runScript,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
