import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/website_vault_type.dart';

class WebsiteVaultTypeFilterChips extends StatelessWidget {
  final WebsiteVaultType? selected;
  final ValueChanged<WebsiteVaultType?> onChanged;

  const WebsiteVaultTypeFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = <WebsiteVaultType?>[
      null,
      WebsiteVaultType.screenshot,
      WebsiteVaultType.pdf,
      WebsiteVaultType.link,
      WebsiteVaultType.download,
      WebsiteVaultType.note,
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final active = selected == type;
          final theme = Theme.of(context);
          return ChoiceChip(
            selected: active,
            label: Text(
              type == null ? 'All' : type.label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            backgroundColor: theme.cardColor,
            side: BorderSide(
              color: active
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.35),
            ),
            onSelected: (_) => onChanged(type),
          );
        },
      ),
    );
  }
}
