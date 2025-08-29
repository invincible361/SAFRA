import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color backgroundTop = Color(0xFF242C3B);
  static const Color backgroundBottom = Color(0xFF2B3D80);
  static const Color surface = Color(0xFF1E2A47);
  static const Color cardBackground = Color(0xFF2A2A2A);
  static const Color darkBackground = Color(0xFF121212);
  static const Color appBarBackground = Color(0xFF1F1F1F);
  static const Color postInputBackground = Color(0xFF1E1E1E);
  static const Color postCardBackground = Color(0xFF1F1F1F);

  // Accent Colors
  static const Color primaryAccent = Color(0xFF6C63FF); // neon purple
  static const Color secondaryAccent = Color(0xFF00D4FF); // neon cyan

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8D1);
  static const Color textMuted = Color(0xFF8A8A8A);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

  // Glass Effect
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
