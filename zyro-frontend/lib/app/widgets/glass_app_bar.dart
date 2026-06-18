import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/tab_model.dart';
import 'glass_container.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassAppBar extends StatefulWidget {
  final TabModel tab;
  const GlassAppBar({super.key, required this.tab});

  @override
  State<GlassAppBar> createState() => _GlassAppBarState();
}

class _GlassAppBarState extends State<GlassAppBar> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.url);
  }

  @override
  void didUpdateWidget(GlassAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.url != oldWidget.tab.url && !_isFocused) {
      _controller.text = widget.tab.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(String value) {
    String input = value.trim();
    if (input.isEmpty) return;

    String url;
    try {
      if (input.startsWith('http://') || input.startsWith('https://')) {
        url = input;
      } else if (input.contains(' ') || !input.contains('.')) {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
      } else {
        url = 'https://$input';
      }

      print("Loading URL: $url");
      
      if (widget.tab.controller != null) {
        widget.tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      } else {
        print("Error: WebView controller is null for tab ${widget.tab.id}");
      }
    } catch (e) {
      print("Error processing URL: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GlassContainer(
            borderRadius: 16,
            opacity: isDark ? 0.08 : 0.05,
            color: theme.colorScheme.onSurface,
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(isDark ? 0.1 : 0.15),
              width: 1.0,
            ),
            child: Container(
              height: 56,
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildSecurityIndicator(theme),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      keyboardType: TextInputType.url,
                      textAlignVertical: TextAlignVertical.center,
                      onSubmitted: (value) {
                        _onSubmitted(value);
                        FocusScope.of(context).unfocus();
                        setState(() => _isFocused = false);
                      },
                      onTap: () => setState(() => _isFocused = true),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                        setState(() => _isFocused = false);
                      },
                      style: GoogleFonts.outfit(
                        fontSize: 14, 
                        color: theme.colorScheme.onSurface, 
                        letterSpacing: 0.2
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        hintText: 'Search or enter URL',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                        suffixIcon: _buildSuffixIcon(theme),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.rotateCcw, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    onPressed: () => widget.tab.controller?.reload(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        _buildProgressBar(theme),
      ],
    );
  }

  Widget _buildSecurityIndicator(ThemeData theme) {
    if (widget.tab.isIncognito) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.eyeOff,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              "PRIVATE",
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final isSecure = widget.tab.url.startsWith('https');
    final color = isSecure ? theme.colorScheme.secondary : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSecure ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            size: 14,
            color: color,
          ),
          if (isSecure) ...[
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (_controller.text.isEmpty) return null;
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.arrowRight, size: 16, color: theme.colorScheme.primary),
      ),
      onPressed: () {
        _onSubmitted(_controller.text);
        FocusScope.of(context).unfocus();
        setState(() => _isFocused = false);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    if (!widget.tab.isLoading) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: widget.tab.progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          minHeight: 2,
        ),
      ),
    );
  }
}
