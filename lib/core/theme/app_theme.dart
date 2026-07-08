import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static List<String> get _vazirmatnFallback => [GoogleFonts.vazirmatn().fontFamily!];

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    surfaceColor: AppColors.darkSurface,
    textColor: AppColors.darkText,
    textSecondaryColor: AppColors.darkTextSecondary,
    dividerColor: AppColors.darkDivider,
    cardElevation: 0.0,
    cardShadowColor: null,
  );

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    surfaceColor: AppColors.lightSurface,
    textColor: AppColors.lightText,
    textSecondaryColor: AppColors.lightTextSecondary,
    dividerColor: AppColors.lightDivider,
    cardElevation: 2.0,
    cardShadowColor: Colors.black.withValues(alpha: 0.1),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondaryColor,
    required Color dividerColor,
    required double cardElevation,
    Color? cardShadowColor,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: (isDark ? ColorScheme.dark : ColorScheme.light)(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: surfaceColor,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.copyWith(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          bodyLarge: TextStyle(fontSize: 16, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          bodyMedium: TextStyle(fontSize: 14, color: textSecondaryColor, fontFamilyFallback: _vazirmatnFallback),
          bodySmall: TextStyle(fontSize: 12, color: textSecondaryColor, fontFamilyFallback: _vazirmatnFallback),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor, fontFamilyFallback: _vazirmatnFallback),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondaryColor, fontFamilyFallback: _vazirmatnFallback),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondaryColor, fontFamilyFallback: _vazirmatnFallback),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: cardElevation,
        shadowColor: cardShadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: textSecondaryColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(color: textColor, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: dividerColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        contentTextStyle: TextStyle(fontSize: 14, color: textSecondaryColor),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
