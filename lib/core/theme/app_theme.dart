import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// Application theme configuration with locale-aware font selection
class AppTheme {
  /// Private constructor
  AppTheme._();

  /// Get theme data for the given locale
  static ThemeData getTheme(Locale locale) {
    final isArabic = locale.languageCode == 'ar';

    // Font families - Cairo for Arabic, Inter for English
    final primaryFontFamily = isArabic
        ? GoogleFonts.cairo().fontFamily
        : GoogleFonts.inter().fontFamily;

    final headingsFontFamily = isArabic
        ? GoogleFonts.cairo().fontFamily
        : GoogleFonts.poppins().fontFamily;

    // Base Text Themes
    final baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : GoogleFonts.interTextTheme();

    final headingsTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : GoogleFonts.poppinsTextTheme();

    // Adjusted text styles for Arabic (slightly larger for readability)
    final fontSizeMultiplier = isArabic ? 1.05 : 1.0;
    final lineHeightMultiplier = isArabic ? 1.6 : 1.5;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.textSecondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // Global font family
      fontFamily: primaryFontFamily,

      // Text Theme configuration with proper Arabic support
      textTheme: _buildTextTheme(
        baseTextTheme,
        headingsTextTheme,
        fontSizeMultiplier,
        lineHeightMultiplier,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: headingsTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20 * fontSizeMultiplier,
          fontWeight: FontWeight.w600,
          fontFamily: headingsFontFamily,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontFamily: headingsFontFamily,
            fontSize: 16 * fontSizeMultiplier,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyle(
            fontFamily: headingsFontFamily,
            fontSize: 16 * fontSizeMultiplier,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyle(
            fontFamily: primaryFontFamily,
            fontSize: 14 * fontSizeMultiplier,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        hintStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14 * fontSizeMultiplier,
          fontWeight: FontWeight.w400,
          color: Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: headingsTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 20 * fontSizeMultiplier,
          fontWeight: FontWeight.w600,
          fontFamily: headingsFontFamily,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14 * fontSizeMultiplier,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16 * fontSizeMultiplier,
          fontWeight: FontWeight.w500,
          fontFamily: primaryFontFamily,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14 * fontSizeMultiplier,
          fontFamily: primaryFontFamily,
          color: AppColors.textSecondary,
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14 * fontSizeMultiplier,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14 * fontSizeMultiplier,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: AppColors.primary,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12 * fontSizeMultiplier,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 12 * fontSizeMultiplier,
        ),
        type: BottomNavigationBarType.fixed,
      ),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.background),
    );
  }

  /// Build text theme with proper sizing and styling
  static TextTheme _buildTextTheme(
    TextTheme baseTextTheme,
    TextTheme headingsTextTheme,
    double fontSizeMultiplier,
    double lineHeightMultiplier,
  ) {
    return TextTheme(
      // Display styles
      displayLarge: headingsTextTheme.displayLarge?.copyWith(
        fontSize: 57 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      displayMedium: headingsTextTheme.displayMedium?.copyWith(
        fontSize: 45 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      displaySmall: headingsTextTheme.displaySmall?.copyWith(
        fontSize: 36 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),

      // Headline styles
      headlineLarge: headingsTextTheme.headlineLarge?.copyWith(
        fontSize: 28 * fontSizeMultiplier,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      headlineMedium: headingsTextTheme.headlineMedium?.copyWith(
        fontSize: 24 * fontSizeMultiplier,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      headlineSmall: headingsTextTheme.headlineSmall?.copyWith(
        fontSize: 20 * fontSizeMultiplier,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),

      // Title styles
      titleLarge: headingsTextTheme.titleLarge?.copyWith(
        fontSize: 22 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      titleMedium: headingsTextTheme.titleMedium?.copyWith(
        fontSize: 16 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      titleSmall: headingsTextTheme.titleSmall?.copyWith(
        fontSize: 14 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),

      // Body styles
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: lineHeightMultiplier,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: lineHeightMultiplier,
      ),

      // Label styles
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: lineHeightMultiplier,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: lineHeightMultiplier,
      ),
    );
  }

  /// Get light theme (alias for getTheme)
  static ThemeData light(Locale locale) => getTheme(locale);

  /// Get dark theme (for future implementation)
  static ThemeData dark(Locale locale) {
    // Future: Implement dark theme
    return getTheme(locale);
  }
}
