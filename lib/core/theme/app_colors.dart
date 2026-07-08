import 'package:flutter/material.dart';

class AppColors {
  // ═══════════════════════════════════════════
  // CINEMA PALETTE - NextUp 2026
  // ═══════════════════════════════════════════

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE50914), Color(0xFFFF3D47)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF5C518), Color(0xFFFFD93D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cinemaGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFE50914)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary Colors
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB20710);
  static const Color primaryLight = Color(0xFFFF3D47);
  static const Color accent = Color(0xFFF5C518);

  // Accent Colors
  static const Color electricPurple = Color(0xFF6C63FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonPink = Color(0xFFFF006E);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF252540);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8B8BA3);
  static const Color darkDivider = Color(0xFF2A2A3E);

  // Light Theme
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F1F6);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);
  static const Color lightDivider = Color(0xFFE8E8F0);

  // Status Colors
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00D4FF);

  // ═══════════════════════════════════════════
  // THEME-AWARE HELPERS
  // ═══════════════════════════════════════════

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03);

  static Color cardBgStrong(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

  static Color border(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);

  static Color borderLight(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);

  static Color text(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? Colors.white54 : Colors.black38;

  static Color icon(BuildContext context) =>
      isDark(context) ? Colors.white70 : Colors.black54;

  static Color iconMuted(BuildContext context) =>
      isDark(context) ? Colors.white38 : Colors.black26;

  static Color divider(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  static List<Color> pageGradient(BuildContext context) =>
      isDark(context)
          ? [darkBackground, darkSurface]
          : [lightBackground, const Color(0xFFE8E8F0)];

  // Glass effect colors
  static Color glassBg(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7);

  static Color glassBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5);

  static Color glassShadow(BuildContext context) =>
      isDark(context) ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08);

  // Rating colors
  static Color ratingHigh = const Color(0xFF00FF88);
  static Color ratingMid = const Color(0xFFFFD93D);
  static Color ratingLow = const Color(0xFFFF4757);

  static Color ratingColor(double rating) {
    if (rating >= 7) return ratingHigh;
    if (rating >= 5) return ratingMid;
    return ratingLow;
  }
}
