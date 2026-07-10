import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const List<String> _vazirmatnFallback = ['Vazirmatn'];

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

    // Build text theme manually with Poppins primary + Vazirmatn fallback
    final baseTextTheme = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
      titleSmall: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      bodyLarge: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 16, color: textColor),
      bodyMedium: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 14, color: textSecondaryColor),
      bodySmall: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 12, color: textSecondaryColor),
      labelLarge: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 12, fontWeight: FontWeight.w500, color: textSecondaryColor),
      labelSmall: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 10, fontWeight: FontWeight.w500, color: textSecondaryColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: 'Poppins',
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
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
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
          textStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 16, fontWeight: FontWeight.w600),
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
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, color: textColor, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: dividerColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
        contentTextStyle: TextStyle(fontFamily: 'Poppins', fontFamilyFallback: _vazirmatnFallback, fontSize: 14, color: textSecondaryColor),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
