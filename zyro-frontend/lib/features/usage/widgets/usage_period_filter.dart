import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/usage_period.dart';

class UsagePeriodFilter extends StatelessWidget {
  final UsagePeriod selected;
  final ValueChanged<UsagePeriod> onChanged;

  const UsagePeriodFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: UsagePeriod.values.map((period) {
          final active = selected == period;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
