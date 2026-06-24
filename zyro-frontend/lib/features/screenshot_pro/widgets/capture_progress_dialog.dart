import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CaptureProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progress;
  final String message;
  const CaptureProgressDialog({
    super.key,
    required this.progress,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    content: ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (_, value, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: value == 0 ? null : value),
          const SizedBox(height: 10),
          Text(
            value == 0 ? 'Preparing…' : '${(value * 100).round()}%',
            style: GoogleFonts.outfit(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
