import 'package:flutter/material.dart';

class FloatingVideoOverlay extends StatelessWidget {
  const FloatingVideoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Return empty widget to disable the in-page overlay entirely.
    // Floating Video triggers native Picture-in-Picture on minimization instead.
    return const SizedBox.shrink();
  }
}
