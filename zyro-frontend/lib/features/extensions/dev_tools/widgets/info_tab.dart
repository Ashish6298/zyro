import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InfoTab extends StatefulWidget {
  final InAppWebViewController webViewController;

  const InfoTab({
    super.key,
    required this.webViewController,
  });

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  String _title = 'Loading...';
  String _url = 'Loading...';
  String _userAgent = 'Loading...';
  String _screenSize = 'Loading...';
  bool _isSecure = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPageInfo();
  }

  Future<void> _loadPageInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = await widget.webViewController.getUrl();
      final title = await widget.webViewController.getTitle();
      
      final dynamic ua = await widget.webViewController.evaluateJavascript(source: "navigator.userAgent");
      final dynamic width = await widget.webViewController.evaluateJavascript(source: "window.innerWidth");
      final dynamic height = await widget.webViewController.evaluateJavascript(source: "window.innerHeight");

      setState(() {
        _url = url?.toString() ?? 'Unknown';
        _title = title ?? 'Untitled';
        _userAgent = ua?.toString() ?? 'Unknown';
        _screenSize = '${width ?? 0} x ${height ?? 0} px';
        _isSecure = url?.scheme == 'https';
      });
    } catch (e) {
      print("Error loading page info: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Security Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (_isSecure ? Colors.green : Colors.orangeAccent).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (_isSecure ? Colors.green : Colors.orangeAccent).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isSecure ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                color: _isSecure ? Colors.green : Colors.orangeAccent,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSecure ? 'Secure Connection' : 'Connection Not Secure',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _isSecure ? Colors.green : Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSecure 
                          ? 'This page is served securely over HTTPS. Traffic is encrypted.'
                          : 'This page is served over HTTP. Traffic may be intercepted.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Info details list
        _buildInfoCard(
          theme,
          isDark,
          title: 'Page Title',
          value: _title,
          icon: LucideIcons.heading,
        ),
        _buildInfoCard(
          theme,
          isDark,
          title: 'URL Address',
          value: _url,
          icon: LucideIcons.globe,
          trailing: IconButton(
            icon: const Icon(LucideIcons.copy, size: 14),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _url));
              _showNotification('URL copied to clipboard');
            },
          ),
        ),
        _buildInfoCard(
          theme,
          isDark,
          title: 'User Agent',
          value: _userAgent,
          icon: LucideIcons.laptop,
          trailing: IconButton(
            icon: const Icon(LucideIcons.copy, size: 14),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _userAgent));
              _showNotification('User Agent copied');
            },
          ),
        ),
        _buildInfoCard(
          theme,
          isDark,
          title: 'Viewport Size',
          value: _screenSize,
          icon: LucideIcons.maximize2,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme,
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.05 : 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  value,
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}
