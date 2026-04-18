/// Mirrors the Android app's terminal/neon palette (bg_deep,
/// accent_green, accent_cyan, text_primary/secondary/tertiary).
library;

import 'package:flutter/material.dart';

class AppColors {
  static const bgDeep = Color(0xFF05080F);
  static const bgPanel = Color(0xFF0A1020);
  static const bgPanelAlt = Color(0xFF0D1424);
  static const textPrimary = Color(0xFFE0E6ED);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textTertiary = Color(0xFF6B7280);
  static const accentGreen = Color(0xFF00FF88);
  static const accentCyan = Color(0xFF00D9FF);
  static const accentRed = Color(0xFFFF3366);
  static const accentPurple = Color(0xFFB14AFF);
  static const border = Color(0xFF1E2A40);
}

ThemeData buildAppTheme() {
  const mono = 'monospace';
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgDeep,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.bgDeep,
      primary: AppColors.accentGreen,
      secondary: AppColors.accentCyan,
      error: AppColors.accentRed,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: mono,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPanel,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
