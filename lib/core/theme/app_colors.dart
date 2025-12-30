import 'package:flutter/material.dart';

class AppColors {
  // --- Classic Theme (Default) ---
  static const Color primary = Color(0xFF8B5A2B);
  static const Color primaryDark = Color(0xFF5D4037);
  static const Color primaryLight = Color(0xFFBCAAA4);
  static const Color background = Color(0xFFFDF8F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF3E2723);
  static const Color textSecondary = Color(0xFF795548);
  static const Color border = Color(0xFFEFEBE9);

  // --- Modern Dark Theme ---
  static const Color darkPrimary = Color(0xFF6366F1); // Indigo
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // --- Ocean Blue Theme ---
  static const Color oceanPrimary = Color(0xFF0EA5E9); // Sky Blue
  static const Color oceanSecondary = Color(0xFF2DD4BF); // Teal
  static const Color oceanBackground = Color(0xFFF0F9FF);
  static const Color oceanSurface = Colors.white;
  static const Color oceanTextPrimary = Color(0xFF0C4A6E);
  static const Color oceanTextSecondary = Color(0xFF0369A1);
  static const Color oceanBorder = Color(0xFFE0F2FE);

  // --- Glassy Theme (Transparent/Blur based) ---
  static const Color glassyPrimary = Color(0xFFFF3366); // Vibrant Pink
  static const Color glassyBackground =
      Colors.transparent; // Will use a background image/gradient
  static const Color glassySurface = Color(0x33FFFFFF); // Ultra-translucent
  static const Color glassyTextPrimary = Colors.white;
  static const Color glassyTextSecondary = Color(0xB3FFFFFF);
  static const Color glassyBorder = Color(0x4DFFFFFF);

  // Status (Common across themes or slightly adjusted)
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFE53935);
  static const Color error = Color(0xFFD32F2F);

  // UI Elements
  static const Color textInverse = Colors.white;
  static const Color inputBackground = Colors.white;
  static const Color iconColor = Color(0xFF8D6E63);
}
