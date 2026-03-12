import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'preferred_language';
  String _currentLanguage = 'en'; // Default to English

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;

    _currentLanguage = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
    notifyListeners();
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'hi':
        return 'Hindi (हिन्दी)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      case 'en':
      default:
        return 'English';
    }
  }
}
