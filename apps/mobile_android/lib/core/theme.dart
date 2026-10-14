import 'package:flutter/material.dart';

class ObsidianTheme {
  // Brand Forensic Palette
  static const Color obsidianBackground = Color(0xFF090A0F);
  static const Color surfaceGlass = Color(0xFF131722);
  static const Color surfaceGlassHigh = Color(0xFF1C2234);
  static const Color borderSubtle = Color(0xFF242C43);
  static const Color borderGlow = Color(0xFF3B486E);

  // Entity Accent Colors
  static const Color neonCyan = Color(0xFF00F0FF); // Companies
  static const Color neonAmber = Color(0xFFFFB800); // Officers & Directors
  static const Color neonPurple = Color(0xFFA855F7); // Beneficial Owners
  static const Color neonGreen = Color(0xFF10B981); // Verified & Active
  static const Color alertRed = Color(0xFFEF4444); // Dissolved / Warning

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBackground,
      primaryColor: neonCyan,
      cardColor: surfaceGlass,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonAmber,
        surface: surfaceGlass,
        background: obsidianBackground,
        error: alertRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: obsidianBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        iconTheme: IconThemeData(color: neonCyan),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: obsidianBackground,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceGlass,
        modalBackgroundColor: surfaceGlass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
