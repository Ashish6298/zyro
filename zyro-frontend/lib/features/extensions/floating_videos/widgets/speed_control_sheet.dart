import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpeedControlSheet extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const SpeedControlSheet({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0, 3.0];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Playback Speed',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...speeds.map((speed) {
            final isSelected = speed == currentSpeed;
            return ListTile(
              title: Text(
                speed == 1.0 ? 'Normal (1.0x)' : '${speed}x',
                style: GoogleFonts.outfit(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary, size: 18)
                  : const SizedBox(width: 18),
              onTap: () {
                onSpeedSelected(speed);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
