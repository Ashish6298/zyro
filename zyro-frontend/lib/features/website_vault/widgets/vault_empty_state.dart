import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VaultEmptyState extends StatelessWidget {
  final String message;
  final bool onboarding;

  const VaultEmptyState({
    super.key,
    required this.message,
    this.onboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!onboarding) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VaultIllustration(size: 72),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        const _VaultIllustration(size: 112),
        const SizedBox(height: 18),
        Text(
          'Your Website Vault is Ready',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: const [
            Expanded(
              child: _HowItWorksCard(
                icon: LucideIcons.bookmarkPlus,
                title: 'Save',
                description: 'Capture pages, files, links, and notes.',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _HowItWorksCard(
                icon: LucideIcons.folderOpen,
                title: 'Organize',
                description: 'Zyro groups everything by website.',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _HowItWorksCard(
                icon: LucideIcons.search,
                title: 'Access',
                description: 'Find important items when needed.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VaultIllustration extends StatelessWidget {
  final double size;

  const _VaultIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.18),
              theme.colorScheme.tertiary.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(size * 0.16),
            ),
            child: Icon(
              LucideIcons.archive,
              color: theme.colorScheme.primary,
              size: size * 0.28,
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HowItWorksCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 124),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.cardColor,
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 10,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
