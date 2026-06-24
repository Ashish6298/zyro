import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/browser_data_manager.dart';
import '../../../core/theme/theme_controller.dart';
import 'developer_info_screen.dart';
import '../../extensions/ad_blocker/widgets/ad_block_settings_stats_widget.dart';
import '../../permissions/screens/website_permissions_screen.dart';
import '../../screenshot_pro/controllers/screenshot_pro_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(context);

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
              'SETTINGS',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Configure browser preferences',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader(theme, 'APPEARANCE'),
          _buildThemeSelector(themeController),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'PRIVACY'),
          SettingTile(
            icon: LucideIcons.history,
            title: 'Clear History',
            onTap: () {
              context.read<BrowserDataManager>().clearHistory();
              _showDone(context);
            },
          ),
          SettingTile(
            icon: LucideIcons.bookmark,
            title: 'Clear Bookmarks',
            onTap: () {
              context.read<BrowserDataManager>().clearBookmarks();
              _showDone(context);
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'PERMISSIONS'),
          SettingTile(
            icon: LucideIcons.shieldCheck,
            title: 'Website Permissions',
            subtitle:
                'Manage camera, microphone, location, notifications, and clipboard access',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebsitePermissionsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          _buildSectionHeader(theme, 'SCREENSHOT PRO'),
          Consumer<ScreenshotProController>(
            builder: (context, controller, _) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(.4)),
              ),
              child: SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Screenshot Pro',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Show floating capture button',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface.withOpacity(.4),
                    fontSize: 11,
                  ),
                ),
                value: controller.enabled,
                onChanged: controller.setEnabled,
              ),
            ),
          ),
          const SizedBox(height: 10),

          const AdBlockSettingsStatsWidget(),
          const SizedBox(height: 24),

          _buildSectionHeader(theme, 'ABOUT'),
          SettingTile(
            customLeading: Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
            title: 'Zyro Browser',
            subtitle: 'Version 1.0.0',
            onTap: null,
          ),
          SettingTile(
            icon: LucideIcons.user,
            title: 'Developer Details',
            // subtitle: 'Developer details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeveloperInfoScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: theme.colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeController themeController) {
    return Row(
      children: [
        Expanded(
          child: ThemeModeCard(
            title: 'Light',
            icon: LucideIcons.sun,
            isSelected: themeController.themeMode == ThemeMode.light,
            onTap: () => themeController.setThemeMode(ThemeMode.light),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ThemeModeCard(
            title: 'Dark',
            icon: LucideIcons.moon,
            isSelected: themeController.themeMode == ThemeMode.dark,
            onTap: () => themeController.setThemeMode(ThemeMode.dark),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ThemeModeCard(
            title: 'System',
            icon: LucideIcons.monitor,
            isSelected: themeController.themeMode == ThemeMode.system,
            onTap: () => themeController.setThemeMode(ThemeMode.system),
          ),
        ),
      ],
    );
  }

  void _showDone(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Action Completed',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ThemeModeCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ThemeModeCard> createState() => _ThemeModeCardState();
}

class _ThemeModeCardState extends State<ThemeModeCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withOpacity(isDark ? 0.15 : 0.08)
                : (isDark ? theme.cardColor.withOpacity(0.5) : theme.cardColor),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? activeColor
                  : (isDark
                        ? theme.dividerColor.withOpacity(0.06)
                        : theme.dividerColor.withOpacity(0.4)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? activeColor.withOpacity(0.1)
                    : (isDark
                          ? Colors.black.withOpacity(0.15)
                          : Colors.black.withOpacity(0.01)),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? activeColor
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: widget.isSelected
                      ? activeColor
                      : theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingTile extends StatefulWidget {
  final IconData? icon;
  final Widget? customLeading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    this.icon,
    this.customLeading,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _scale = 0.98),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              widget.onTap!();
            },
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor.withOpacity(0.4) : theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? theme.dividerColor.withOpacity(0.06)
                  : theme.dividerColor.withOpacity(0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.15)
                    : Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.customLeading != null)
                widget.customLeading!
              else if (widget.icon != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon!,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
