import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium HSL-inspired palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color background = Color(0xFF0F172A); // Deep slate dark mode
  static const Color surface = Color(0xFF1E293B);
  static const Color textBody = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color accent = Color(0xFF22D3EE); // Cyan

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(color: textBody),
          bodyMedium: TextStyle(color: textBody),
          titleLarge: TextStyle(color: textBody, fontWeight: FontWeight.bold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
