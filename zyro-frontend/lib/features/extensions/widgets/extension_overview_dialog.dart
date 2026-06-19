import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/models/extension_model.dart';

class ExtensionOverviewDetails {
  final String description;
  final List<String> features;
  final String benefits;
  final String privacyNotes;
  final String permissionsSummary;

  const ExtensionOverviewDetails({
    required this.description,
    required this.features,
    required this.benefits,
    required this.privacyNotes,
    required this.permissionsSummary,
  });

  static const Map<String, ExtensionOverviewDetails> metadata = {
    'ad_blocker_downloader': ExtensionOverviewDetails(
      description: 'Blocks intrusive ads/trackers and detects downloadable videos on YouTube and standard web pages.',
      features: [
        'Advanced ad-blocking scripts matching web headers',
        'Automatic media stream link sniffer',
        'Floating quick-download overlay on detected videos',
        'High speed local download manager support'
      ],
      benefits: 'Reduces loading times, saves network data bandwidth, and enables easy offline video playback.',
      permissionsSummary: 'Requires permissions to modify page network contents and write video files to device storage.',
      privacyNotes: 'Local processing only. We do not transmit web URLs or search history to external servers.',
    ),
    'dev_tools': ExtensionOverviewDetails(
      description: 'Developer utilities mimicking PC browser inspector toolsets directly on your mobile device.',
      features: [
        'Inspect and highlight active DOM layout nodes',
        'View console warnings, errors, and log prints',
        'Trace web request links and network status codes',
        'Access and inspect localStorage/sessionStorage keys'
      ],
      benefits: 'Enables debugging, styling adjustments, and network logging on the go.',
      permissionsSummary: 'Requires permission to read page elements and web consoles upon request.',
      privacyNotes: 'No data is uploaded. Network and console logs exist only in-memory and clear on tab close.',
    ),
    'background_player': ExtensionOverviewDetails(
      description: 'Enables background audio/video playback with system notification controls.',
      features: [
        'Continue listening to videos/music when app is minimized',
        'System lock-screen media player notification integrations',
        'Play, Pause, Next, and Previous media session controls',
        'Resilient background service handling'
      ],
      benefits: 'Enables seamless music and video streaming in the background while multitasking.',
      permissionsSummary: 'Requires permissions to show standard media notifications and run a foreground media service.',
      privacyNotes: 'Only tracks active media state in-memory (title, website, play status) to populate controls.',
    ),
    'dark_mode': ExtensionOverviewDetails(
      description: 'Injects smart, eye-friendly dark stylesheets onto every website.',
      features: [
        'Inverts background colors while keeping image integrity',
        'Customizable contrast and brightness parameters',
        'Reduces eye strain under low-light configurations'
      ],
      benefits: 'Improves reading comfort and battery efficiency on OLED screens.',
      permissionsSummary: 'Requires permission to manipulate page stylesheet styling parameters.',
      privacyNotes: 'All stylesheet operations occur locally on the rendering engine.',
    ),
    'password_gen': ExtensionOverviewDetails(
      description: 'Generates secure cryptographically strong password strings.',
      features: [
        'Customizable password length configurations',
        'Toggle uppercase, digits, symbols, and specials',
        'Quick-copy output actions for rapid logins'
      ],
      benefits: 'Encourages account safety by generating secure unique password variables.',
      permissionsSummary: 'Requires clipboard access to paste generated passwords.',
      privacyNotes: 'Passwords are generated strictly in local memory and are never saved or uploaded.',
    ),
  };
}

class ExtensionOverviewDialog extends StatelessWidget {
  final ExtensionModel extension;
  final VoidCallback onConfirm;

  const ExtensionOverviewDialog({
    super.key,
    required this.extension,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final details = ExtensionOverviewDetails.metadata[extension.id] ?? ExtensionOverviewDetails(
      description: extension.description,
      features: const ['Standard extension capabilities'],
      benefits: 'Enhances Zyro Browser functions.',
      permissionsSummary: 'Standard page script permissions.',
      privacyNotes: 'All extension scripts execute locally inside your sandbox.',
    );

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Block (Icon & Name)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      extension.icon,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extension.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version ${extension.version}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                details.description,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              
              // Key Features Header
              Text(
                'KEY FEATURES',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Features list
              ...details.features.map((feat) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.check,
                          color: theme.colorScheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feat,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              
              // How it helps
              Text(
                'BENEFIT',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                details.benefits,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              
              // Permissions Summary
              Text(
                'PERMISSIONS REQUIRED',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                details.permissionsSummary,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              
              // Privacy Note Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface.withOpacity(0.3) : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? theme.dividerColor.withOpacity(0.04) : theme.dividerColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.shield,
                      color: theme.colorScheme.primary.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Commitment',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            details.privacyNotes,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.outfit(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
