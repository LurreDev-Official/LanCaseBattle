import 'package:flutter/material.dart';

/// Cyber-esports / SOC palette — cyan & lime accents (no purple default).
abstract final class ArenaColors {
  static const Color voidBlack = Color(0xFF05080F);
  static const Color deepNavy = Color(0xFF0A1220);
  static const Color panel = Color(0xFF121C2C);
  static const Color panelElevated = Color(0xFF182538);
  static const Color gridLine = Color(0xFF1E2F48);

  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanDim = Color(0xFF0088A3);
  static const Color lime = Color(0xFFB8FF3C);
  static const Color amber = Color(0xFFFFB020);
  static const Color crimson = Color(0xFFFF3B5C);
  static const Color ice = Color(0xFFE8F4FF);
  static const Color muted = Color(0xFF8BA0B8);

  static const Color teamA = Color(0xFF00E5FF);
  static const Color teamB = Color(0xFFB8FF3C);
  static const Color teamC = Color(0xFFFFB020);
  static const Color teamD = Color(0xFFFF6B8A);

  static Color teamAccent(int slot) {
    return switch (slot % 4) {
      0 => teamA,
      1 => teamB,
      2 => teamC,
      _ => teamD,
    };
  }
}
