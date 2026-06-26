import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/models/tab_model.dart';
import 'glass_container.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../features/web_apps/controllers/web_app_installer_controller.dart';

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
        widget.tab.controller?.loadUrl(
          urlRequest: URLRequest(url: WebUri(url)),
        );
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
              color: theme.colorScheme.onSurface.withOpacity(
                isDark ? 0.1 : 0.15,
              ),
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
                        letterSpacing: 0.2,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        hintText: 'Search or enter URL',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 13,
                        ),
                        suffixIcon: _buildSuffixIcon(theme),
                      ),
                    ),
                  ),
                  if (!widget.tab.isIncognito &&
                      widget.tab.url.startsWith('https://'))
                    IconButton(
                      icon: Icon(
                        LucideIcons.download,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Install App',
                      onPressed: () => _install(context),
                    ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.rotateCcw,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
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

  Future<void> _install(BuildContext context) async {
    final apps = context.read<WebAppInstallerController>();
    final candidate = await apps.detectCandidate(widget.tab);
    if (!context.mounted) return;

    final existing = apps.appForUrl(candidate.startUrl);
    final action = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _WebAppInstallDialog(
        candidate: candidate,
        existing: existing,
        onCancel: () => Navigator.pop(dialogContext, false),
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );

    if (action != true) return;
    if (existing != null) {
      widget.tab.controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri(existing.startUrl)),
      );
      return;
    }

    final result = await apps.installCandidate(candidate);
    if (!context.mounted) return;
    final message = result.shortcutSupported
        ? 'App installed in Zyro Apps'
        : 'App installed. Home screen shortcuts are not supported on this device';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildSecurityIndicator(ThemeData theme) {
    if (widget.tab.isIncognito) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade700, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.eyeOff, size: 13, color: Colors.white),
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
    final color = isSecure
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSecure ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            size: 14,
            color: color,
          ),
          if (isSecure) ...[const SizedBox(width: 4)],
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
        child: Icon(
          LucideIcons.arrowRight,
          size: 16,
          color: theme.colorScheme.primary,
        ),
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

class _WebAppInstallDialog extends StatelessWidget {
  final WebAppInstallCandidate candidate;
  final InstalledWebApp? existing;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _WebAppInstallDialog({
    required this.candidate,
    required this.existing,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInstalled = existing != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _WebAppIconPreview(candidate: candidate)),
              const SizedBox(height: 16),
              Text(
                isInstalled
                    ? 'Already installed'
                    : 'Install ${candidate.name}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                candidate.domain,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  isInstalled
                      ? '${existing!.name} is already saved in Zyro Apps.'
                      : 'This will save the website in Zyro Apps and request Android to add a shortcut on your home screen. You may see a final Android confirmation before the shortcut is added.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
              ),
              if (!isInstalled) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Column(
                    children: [
                      _InstallInfoRow(
                        icon: LucideIcons.smartphone,
                        text: 'Creates a home screen shortcut',
                      ),
                      _InstallInfoRow(
                        icon: LucideIcons.layoutGrid,
                        text: 'Saves inside Zyro Apps',
                      ),
                      _InstallInfoRow(
                        icon: LucideIcons.compass,
                        text: 'Opens inside Zyro Browser',
                      ),
                      _InstallInfoRow(
                        icon: LucideIcons.trash2,
                        text: 'Can be removed later',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(isInstalled ? 'Open App' : 'Continue'),
                    ),
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

class _WebAppIconPreview extends StatelessWidget {
  final WebAppInstallCandidate candidate;

  const _WebAppIconPreview({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: candidate.iconUrl == null
            ? _FallbackWebAppIcon(name: candidate.name)
            : Image.network(
                candidate.iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _FallbackWebAppIcon(name: candidate.name),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _FallbackWebAppIcon(name: candidate.name);
                },
              ),
      ),
    );
  }
}

class _FallbackWebAppIcon extends StatelessWidget {
  final String name;

  const _FallbackWebAppIcon({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? 'Z' : name.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InstallInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstallInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.74),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
