import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  static final Map<String, Locale> supportedLocales = {
    'en': const Locale('en'),
    'hi': const Locale('hi'),
    'kn': const Locale('kn'),
  };
  
  static final Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी',
    'kn': 'ಕನ್ನಡ',
  };
  
  LanguageService() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    await setLanguage(savedLanguage);
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (supportedLocales.containsKey(languageCode)) {
      _currentLocale = supportedLocales[languageCode]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
  
  String getCurrentLanguageCode() {
    return _currentLocale.languageCode;
  }
  
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }
  
  List<String> getSupportedLanguageCodes() {
    return supportedLocales.keys.toList();
  }
} 