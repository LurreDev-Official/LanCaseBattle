import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color _ink = Color(0xFF1A1F24);
  static const Color _panel = Color(0xFFF7F4EF);
  static const Color _accent = Color(0xFFB45309);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.light,
        surface: _panel,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: _panel,
      appBarTheme: const AppBarTheme(
        backgroundColor: _panel,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _ink,
        displayColor: _ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
