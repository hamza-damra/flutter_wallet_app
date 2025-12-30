import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'theme_provider.dart';

/// Application theme configuration with locale-aware font selection
class AppTheme {
  /// Private constructor
  AppTheme._();

  /// Get theme data for the given locale and theme mode
  static ThemeData getTheme(Locale locale, AppThemeMode mode) {
    final isArabic = locale.languageCode == 'ar';

    // Base colors based on theme mode
    final colors = _getThemeColors(mode);

    // Font families - Cairo for Arabic
    final primaryFontFamily = isArabic
        ? GoogleFonts.cairo().fontFamily
        : (mode == AppThemeMode.modernDark
              ? GoogleFonts.plusJakartaSans().fontFamily
              : GoogleFonts.inter().fontFamily);

    final headingsFontFamily = isArabic
        ? GoogleFonts.cairo().fontFamily
        : (mode == AppThemeMode.modernDark
              ? GoogleFonts.plusJakartaSans().fontFamily
              : (mode == AppThemeMode.glassy
                    ? GoogleFonts.outfit().fontFamily
                    : GoogleFonts.poppins().fontFamily));

    // Base Text Themes
    final baseTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : (mode == AppThemeMode.modernDark
              ? GoogleFonts.plusJakartaSansTextTheme()
              : GoogleFonts.interTextTheme());

    final headingsTextTheme = isArabic
        ? GoogleFonts.cairoTextTheme()
        : (mode == AppThemeMode.modernDark
              ? GoogleFonts.plusJakartaSansTextTheme()
              : (mode == AppThemeMode.glassy
                    ? GoogleFonts.outfitTextTheme()
                    : GoogleFonts.poppinsTextTheme()));

    // Adjusted text styles for Arabic (slightly larger for readability)
    final fontSizeMultiplier = isArabic ? 1.05 : 1.0;
    final lineHeightMultiplier = isArabic ? 1.6 : 1.5;

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: mode == AppThemeMode.modernDark
          ? Brightness.dark
          : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: mode == AppThemeMode.modernDark
            ? Brightness.dark
            : Brightness.light,
        primary: colors.primary,
        onPrimary: colors.textOnPrimary,
        secondary: colors.textSecondary,
        onSecondary: colors.textOnPrimary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: colors.border,
      ),

      // Global font family
      fontFamily: primaryFontFamily,

      // Text Theme configuration
      textTheme: _buildTextTheme(
        baseTextTheme,
        headingsTextTheme,
        fontSizeMultiplier,
        lineHeightMultiplier,
        colors,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor:
            (mode == AppThemeMode.glassy || mode == AppThemeMode.modernDark)
            ? Colors.transparent
            : colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: headingsTextTheme.headlineSmall?.copyWith(
          color: colors.textPrimary,
          fontSize: 20 * fontSizeMultiplier,
          fontWeight: FontWeight.w600,
          fontFamily: headingsFontFamily,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textOnPrimary,
          textStyle: TextStyle(
            fontFamily: headingsFontFamily,
            fontSize: 16 * fontSizeMultiplier,
            fontWeight: FontWeight.w600,
          ),
          elevation: mode == AppThemeMode.glassy ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: TextStyle(
            fontFamily: headingsFontFamily,
            fontSize: 16 * fontSizeMultiplier,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: colors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mode == AppThemeMode.glassy
            ? Colors.white.withValues(alpha: 0.1)
            : (mode == AppThemeMode.modernDark
                  ? colors.surface
                  : AppColors.inputBackground),
        hintStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontSize: 14 * fontSizeMultiplier,
          fontWeight: FontWeight.w400,
          color: colors.textSecondary.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: mode == AppThemeMode.glassy
              ? BorderSide(color: colors.border)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: mode == AppThemeMode.glassy
              ? BorderSide(color: colors.border)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: mode == AppThemeMode.glassy ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: mode == AppThemeMode.glassy
              ? BorderSide(color: colors.border)
              : BorderSide.none,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16 * fontSizeMultiplier,
          fontWeight: FontWeight.w500,
          fontFamily: primaryFontFamily,
          color: colors.textPrimary,
        ),
        subtitleTextStyle: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14 * fontSizeMultiplier,
          fontFamily: primaryFontFamily,
          color: colors.textSecondary,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.textOnPrimary,
        elevation: 4,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: mode == AppThemeMode.modernDark
            ? colors.surface
            : colors.primary,
        contentTextStyle: TextStyle(
          color: colors.textOnPrimary,
          fontFamily: primaryFontFamily,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: mode == AppThemeMode.glassy ? 0 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: mode == AppThemeMode.glassy
              ? BorderSide(color: colors.border)
              : BorderSide.none,
        ),
        titleTextStyle: headingsTextTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),

      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.background,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: mode == AppThemeMode.glassy
            ? Colors.transparent
            : colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: mode == AppThemeMode.glassy ? 0 : 8,
      ),
    );

    return baseTheme;
  }

  /// Helper to get theme-specific colors
  static _ThemeColors _getThemeColors(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.modernDark:
        return _ThemeColors(
          primary: AppColors.darkPrimary,
          background: AppColors.darkBackground,
          surface: AppColors.darkSurface,
          textPrimary: AppColors.darkTextPrimary,
          textSecondary: AppColors.darkTextSecondary,
          textOnPrimary: Colors.white,
          border: AppColors.darkBorder,
        );
      case AppThemeMode.oceanBlue:
        return _ThemeColors(
          primary: AppColors.oceanPrimary,
          background: AppColors.oceanBackground,
          surface: AppColors.oceanSurface,
          textPrimary: AppColors.oceanTextPrimary,
          textSecondary: AppColors.oceanTextSecondary,
          textOnPrimary: Colors.white,
          border: AppColors.oceanBorder,
        );
      case AppThemeMode.glassy:
        return _ThemeColors(
          primary: AppColors.glassyPrimary,
          background: const Color(0xFF020617), // Slate 950 (Deep Dark)
          surface: AppColors.glassySurface,
          textPrimary: AppColors.glassyTextPrimary,
          textSecondary: AppColors.glassyTextSecondary,
          textOnPrimary: Colors.white,
          border: AppColors.glassyBorder,
        );
      case AppThemeMode.classic:
        return _ThemeColors(
          primary: AppColors.primary,
          background: AppColors.background,
          surface: AppColors.surface,
          textPrimary: AppColors.textPrimary,
          textSecondary: AppColors.textSecondary,
          textOnPrimary: Colors.white,
          border: AppColors.border,
        );
    }
  }

  /// Build text theme
  static TextTheme _buildTextTheme(
    TextTheme baseTextTheme,
    TextTheme headingsTextTheme,
    double fontSizeMultiplier,
    double lineHeightMultiplier,
    _ThemeColors colors,
  ) {
    return TextTheme(
      displayLarge: headingsTextTheme.displayLarge?.copyWith(
        fontSize: 57 * fontSizeMultiplier,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      displayMedium: headingsTextTheme.displayMedium?.copyWith(
        fontSize: 45 * fontSizeMultiplier,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      displaySmall: headingsTextTheme.displaySmall?.copyWith(
        fontSize: 36 * fontSizeMultiplier,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      headlineLarge: headingsTextTheme.headlineLarge?.copyWith(
        fontSize: 28 * fontSizeMultiplier,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      headlineMedium: headingsTextTheme.headlineMedium?.copyWith(
        fontSize: 24 * fontSizeMultiplier,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      headlineSmall: headingsTextTheme.headlineSmall?.copyWith(
        fontSize: 20 * fontSizeMultiplier,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      titleLarge: headingsTextTheme.titleLarge?.copyWith(
        fontSize: 22 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      titleMedium: headingsTextTheme.titleMedium?.copyWith(
        fontSize: 16 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      titleSmall: headingsTextTheme.titleSmall?.copyWith(
        fontSize: 14 * fontSizeMultiplier,
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16 * fontSizeMultiplier,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14 * fontSizeMultiplier,
        color: colors.textSecondary,
        height: lineHeightMultiplier,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12 * fontSizeMultiplier,
        color: colors.textSecondary,
        height: lineHeightMultiplier,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14 * fontSizeMultiplier,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12 * fontSizeMultiplier,
        color: colors.textPrimary,
        height: lineHeightMultiplier,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11 * fontSizeMultiplier,
        color: colors.textSecondary,
        height: lineHeightMultiplier,
      ),
    );
  }

  /// Get light theme (alias)
  static ThemeData light(Locale locale) =>
      getTheme(locale, AppThemeMode.classic);

  /// Get dark theme (alias)
  static ThemeData dark(Locale locale) =>
      getTheme(locale, AppThemeMode.modernDark);
}

/// Helper class for internal theme colors
class _ThemeColors {
  final Color primary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textOnPrimary;
  final Color border;

  _ThemeColors({
    required this.primary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnPrimary,
    required this.border,
  });
}
