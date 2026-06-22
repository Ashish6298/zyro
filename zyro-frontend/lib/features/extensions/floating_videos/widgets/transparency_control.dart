import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransparencyControl extends StatelessWidget {
  final double currentOpacity;
  final ValueChanged<double> onOpacityChanged;

  const TransparencyControl({
    super.key,
    required this.currentOpacity,
    required this.onOpacityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Adjust Opacity',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.opacity, size: 20),
              Expanded(
                child: Slider(
                  value: currentOpacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(currentOpacity * 100).toInt()}%',
                  onChanged: onOpacityChanged,
                ),
              ),
              Text(
                '${(currentOpacity * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
