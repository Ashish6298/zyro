import 'package:flutter/material.dart';

class UsageProgressBar extends StatelessWidget {
  final double value;

  const UsageProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 6,
        value: value.clamp(0, 1),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      ),
    );
  }
}
