import 'package:flutter/material.dart';

class AppColors {
  // Premium Dark Theme Palette
  static const Color background = Color(0xFF121212); // Deep rich dark grey
  static const Color surface = Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color gold = Color(0xFFD4AF37); // Metallic Classic Gold
  static const Color softGold = Color(
    0xFFFFD700,
  ); // Lighter gold for highlights
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Text Colors
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xFFB0B0B0); // Silver/Grey
  static const Color textTertiary = Color(0xFF757575);

  // Status Colors
  static const Color errorRed = Color(0xFFCF6679); // Muted red for dark mode
  static const Color successGreen = Color(0xFF81C784); // Muted green
  static const Color warningYellow = Color(0xFFFFB74D); // Muted orange

  // UI Accents
  static const Color cardBorder = Color(0xFF2C2C2C);
  static const Color divider = Color(0xFF2C2C2C);
  static const Color overlay = Color(0xAA000000);

  // Legacy/Compatibility
  static const Color oliveGreen = surface; // Map old olive to surface
  static const Color primaryGold = gold;
  static const Color lightGrey = textSecondary;
  static const Color grey = textTertiary;
  static const Color cream = Color(0xFFFFFDD0); // Restored for compatibility

  // Interactions
  static const Color ripple = Color(0x1AD4AF37); // Gold ripple
}
