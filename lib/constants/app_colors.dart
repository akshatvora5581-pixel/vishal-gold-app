import 'package:flutter/material.dart';
import '../config/whitelabel_config.dart';

class AppColors {
  static BaseConfig get _config => AppEnvironment.config;

  // Premium Dark Theme Palette (Dynamic)
  static Color get background => _config.backgroundColor;
  static Color get surface => _config.surfaceColor;
  static Color get gold => _config.primaryColor;
  static Color get softGold => _config.accentColor;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Text Colors
  static Color get textPrimary => _config.textPrimary;
  static Color get textSecondary => _config.textSecondary;
  static const Color textTertiary = Color(0xFF757575);

  // Status Colors
  static const Color errorRed = Color(0xFFCF6679);
  static const Color successGreen = Color(0xFF81C784);
  static const Color warningYellow = Color(0xFFFFB74D);

  // UI Accents
  static const Color cardBorder = Color(0xFF2C2C2C);
  static const Color divider = Color(0xFF2C2C2C);
  static const Color overlay = Color(0xAA000000);

  // Legacy/Compatibility
  static Color get oliveGreen => surface;
  static Color get primaryGold => gold;
  static Color get lightGrey => textSecondary;
  static const Color grey = textTertiary;
  static const Color cream = Color(0xFFFFFDD0);

  // Interactions
  static Color get ripple => _config.primaryColor.withValues(alpha: 0.1);
}
