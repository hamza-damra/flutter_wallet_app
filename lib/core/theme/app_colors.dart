import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(
    0xFF8B5A2B,
  ); // Brown from description/inference
  static const Color primaryDark = Color(0xFF5D4037);
  static const Color primaryLight = Color(0xFFBCAAA4);

  // Backgrounds
  static const Color background = Color(0xFFFDF8F5); // Warm beige / off-white
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF3E2723); // Dark brown/black
  static const Color textSecondary = Color(0xFF795548); // Muted brown
  static const Color textInverse = Colors.white;

  // Status
  static const Color income = Color(0xFF4CAF50); // Green
  static const Color expense = Color(
    0xFFE53935,
  ); // Red - adjusted to be vibrant but standard
  static const Color error = Color(0xFFD32F2F);

  // UI Elements
  static const Color border = Color(0xFFEFEBE9);
  static const Color inputBackground = Colors.white;
  static const Color iconColor = Color(0xFF8D6E63);
}
