import 'package:flutter/material.dart';

class AppColors {
  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE50914), Color(0xFFFF3D47)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary Colors
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB20710);
  static const Color primaryLight = Color(0xFFFF3D47);
  static const Color accent = Color(0xFFF5C518);

  // Neon Colors
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonGreen = Color(0xFF00FF88);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceLight = Color(0xFF2D2D44);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8B8BA3);
  static const Color darkDivider = Color(0xFF2A2A3E);

  // Light Theme
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF0F1F6);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);
  static const Color lightDivider = Color(0xFFE8E8F0);

  // Status Colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00D4FF);

  // Theme-aware helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color text(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? Colors.white54 : Colors.black38;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);

  static Color border(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

  static Color icon(BuildContext context) =>
      isDark(context) ? Colors.white70 : Colors.black54;

  static Color divider(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  static List<Color> pageGradient(BuildContext context) =>
      isDark(context)
          ? [darkBackground, darkSurface]
          : [lightBackground, const Color(0xFFE8E8F0)];
}
