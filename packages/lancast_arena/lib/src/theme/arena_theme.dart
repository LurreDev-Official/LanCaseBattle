import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lancast_arena/src/theme/arena_colors.dart';

abstract final class ArenaTheme {
  static ThemeData dark() {
    final baseText = GoogleFonts.rajdhaniTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    final display = GoogleFonts.orbitronTextTheme(baseText);

    final scheme = const ColorScheme.dark(
      surface: ArenaColors.deepNavy,
      primary: ArenaColors.cyan,
      secondary: ArenaColors.lime,
      tertiary: ArenaColors.amber,
      error: ArenaColors.crimson,
      onPrimary: ArenaColors.voidBlack,
      onSecondary: ArenaColors.voidBlack,
      onSurface: ArenaColors.ice,
      onError: ArenaColors.ice,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ArenaColors.voidBlack,
      canvasColor: ArenaColors.deepNavy,
      dividerColor: ArenaColors.gridLine,
      textTheme: display.copyWith(
        displayLarge: GoogleFonts.orbitron(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        displayMedium: GoogleFonts.orbitron(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        headlineMedium: GoogleFonts.orbitron(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w600,
          fontSize: 28,
          letterSpacing: 1,
        ),
        titleLarge: GoogleFonts.orbitron(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.rajdhani(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.6,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          color: ArenaColors.muted,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        labelLarge: GoogleFonts.shareTechMono(
          color: ArenaColors.cyan,
          fontSize: 13,
          letterSpacing: 1.4,
        ),
        labelSmall: GoogleFonts.shareTechMono(
          color: ArenaColors.muted,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ArenaColors.deepNavy.withValues(alpha: 0.92),
        foregroundColor: ArenaColors.ice,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          color: ArenaColors.ice,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: 1.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArenaColors.panel,
        labelStyle: const TextStyle(color: ArenaColors.muted),
        hintStyle: const TextStyle(color: ArenaColors.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArenaColors.gridLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ArenaColors.cyan, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ArenaColors.cyan,
          foregroundColor: ArenaColors.voidBlack,
          textStyle: GoogleFonts.orbitron(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ArenaColors.cyan,
          side: const BorderSide(color: ArenaColors.cyanDim),
          textStyle: GoogleFonts.orbitron(
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            fontSize: 12,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ArenaColors.panelElevated,
        contentTextStyle: GoogleFonts.rajdhani(
          color: ArenaColors.ice,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ArenaColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ArenaColors.cyan.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
