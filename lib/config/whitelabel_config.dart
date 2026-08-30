import 'package:flutter/material.dart';

/// Base class for all whitelabel configurations.
abstract class BaseConfig {
  String get appName;
  String get appTagline;
  String get logoPath;
  
  // Theme Colors
  Color get primaryColor;
  Color get accentColor;
  Color get backgroundColor;
  Color get surfaceColor;
  
  // Text Colors
  Color get textPrimary;
  Color get textSecondary;
  
  // Feature Toggles/Constants
  int get itemsPerPage => 20;
  Duration get apiTimeout => const Duration(seconds: 30);
}

/// Implementation for Vishal Jewellers brand.
class VishalJewellersConfig extends BaseConfig {
  @override
  String get appName => 'Vishal Jewellers';
  
  @override
  String get appTagline => 'Dharukawala';
  
  @override
  String get logoPath => 'assets/logo.png';

  @override
  Color get primaryColor => const Color(0xFFD4AF37); // Classic Gold
  
  @override
  Color get accentColor => const Color(0xFFFFD700); // Soft Gold
  
  @override
  Color get backgroundColor => const Color(0xFF121212); // Deep Rich Dark Grey
  
  @override
  Color get surfaceColor => const Color(0xFF1E1E1E); // Slightly Lighter Grey

  @override
  Color get textPrimary => Colors.white;
  
  @override
  Color get textSecondary => const Color(0xFFB0B0B0); // Silver/Grey
}

/// Global provider for the active configuration.
class AppEnvironment {
  static BaseConfig _config = VishalJewellersConfig();

  static BaseConfig get config => _config;

  static void setConfig(BaseConfig config) {
    _config = config;
  }
}
