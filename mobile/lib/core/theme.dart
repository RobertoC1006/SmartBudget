import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SBColors {
  static const primary = Color(0xFF1B8F63);
  static const secondary = Color(0xFF7DD3A7);
  static const dark = Color(0xFF0F3D2E);
  static const light = Color(0xFFF6FFFB);
  static const muted = Color(0xFF5F8072);
}

ThemeData buildTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: SBColors.primary,
      primary: SBColors.primary,
      secondary: SBColors.secondary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
    bodyMedium: GoogleFonts.poppins(color: SBColors.dark),
  );

  return base.copyWith(
    scaffoldBackgroundColor: SBColors.light,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: SBColors.light,
      foregroundColor: SBColors.dark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: SBColors.dark,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: SBColors.primary.withValues(alpha: 0.08),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SBColors.primary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SBColors.primary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SBColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: StadiumBorder(side: BorderSide(color: SBColors.primary.withValues(alpha: 0.2))),
      backgroundColor: Colors.white,
      selectedColor: SBColors.primary.withValues(alpha: 0.12),
      labelStyle: textTheme.labelMedium?.copyWith(color: SBColors.muted),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: SBColors.dark),
    ),
  );
}
