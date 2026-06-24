import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScreenshotOptionsSheet extends StatelessWidget {
  final VoidCallback onVisible;
  final VoidCallback onFull;
  const ScreenshotOptionsSheet({super.key, required this.onVisible, required this.onFull});
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('SCREENSHOT PRO', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
    ListTile(leading: const Icon(LucideIcons.camera), title: const Text('Take Screenshot'), subtitle: const Text('Capture visible webpage'), onTap: onVisible),
    ListTile(leading: const Icon(LucideIcons.arrowDown), title: const Text('Full Screenshot'), subtitle: const Text('Capture full webpage'), onTap: onFull),
  ])));
}
