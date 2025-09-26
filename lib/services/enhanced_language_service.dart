import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';

class EnhancedLanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  Locale _currentLocale = const Locale('en');
  bool _isLoading = false;
  String _translationProvider = 'libre'; // 'google' or 'libre' - default to libre
  
  Locale get currentLocale => _currentLocale;
  bool get isLoading => _isLoading;
  String get translationProvider => _translationProvider;
  
  // Static translations for common UI elements
         static const Map<String, Map<String, String>> _staticTranslations = {
           'en': {
             'appTitle': 'SAFRA App',
             'welcome': 'Welcome Back',
             'getStarted': "Let's Get Started",
             'login': 'Login',
             'email': 'Email',
             'password': 'Password',
             'signInWithGoogle': 'Sign in with Google',
             'signOut': 'Sign Out',
             'cancel': 'Cancel',
             'ok': 'OK',
             'error': 'Error',
             'success': 'Success',
             'loading': 'Loading...',
             'map': 'Map',
             'settings': 'Settings',
             'securitySettings': 'Security Settings',
             'forgotPassword': 'Forgot Password?',
             'dontHaveAccount': "Don't have an account?",
             'signUp': 'Sign Up',
             'or': 'OR',
           },
           'hi': {
             'appTitle': 'सफरा ऐप',
             'welcome': 'वापसी पर स्वागत है',
             'getStarted': 'आइए शुरू करते हैं',
             'login': 'लॉगिन',
             'email': 'ईमेल',
             'password': 'पासवर्ड',
             'signInWithGoogle': 'Google से साइन इन करें',
             'signOut': 'साइन आउट',
             'cancel': 'रद्द करें',
             'ok': 'ठीक है',
             'error': 'त्रुटि',
             'success': 'सफलता',
             'loading': 'लोड हो रहा है...',
             'map': 'मानचित्र',
             'settings': 'सेटिंग्स',
             'securitySettings': 'सुरक्षा सेटिंग्स',
             'forgotPassword': 'पासवर्ड भूल गए?',
             'dontHaveAccount': 'खाता नहीं है?',
             'signUp': 'साइन अप करें',
             'or': 'या',
           },
           'kn': {
             'appTitle': 'ಸಫರಾ ಅಪ್ಲಿಕೇಶನ್',
             'welcome': 'ಮತ್ತೆ ಸುಸ್ವಾಗತ',
             'getStarted': 'ಆರಂಭಿಸೋಣ',
             'login': 'ಲಾಗಿನ್',
             'email': 'ಇಮೇಲ್',
             'password': 'ಪಾಸ್‌ವರ್ಡ್',
             'signInWithGoogle': 'Google ನೊಂದಿಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
             'signOut': 'ಸೈನ್ ಔಟ್',
             'cancel': 'ರದ್ದುಮಾಡಿ',
             'ok': 'ಸರಿ',
             'error': 'ದೋಷ',
             'success': 'ಯಶಸ್ವಿ',
             'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
             'map': 'ನಕ್ಷೆ',
             'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
             'securitySettings': 'ಸುರಕ್ಷತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
             'forgotPassword': 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿದ್ದೀರಾ?',
             'dontHaveAccount': 'ಖಾತೆ ಇಲ್ಲವೇ?',
             'signUp': 'ಸೈನ್ ಅಪ್',
             'or': 'ಅಥವಾ',
           },
  };
  
  static final Map<String, Locale> supportedLocales = {
    'en': const Locale('en'),
    'hi': const Locale('hi'),
    'kn': const Locale('kn'),
  };
  
  EnhancedLanguageService() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
      await setLanguage(savedLanguage);
    } catch (e) {
      print('Error loading saved language: $e');
      // Fallback to default language
      _currentLocale = const Locale('en');
      notifyListeners();
    }
  }
  
  Future<void> setLanguage(String languageCode) async {
    print('EnhancedLanguageService: Attempting to set language to: $languageCode');
    print('EnhancedLanguageService: Supported languages: ${supportedLocales.keys}');
    
    if (supportedLocales.containsKey(languageCode)) {
      print('EnhancedLanguageService: Language $languageCode is supported, setting locale');
      _currentLocale = supportedLocales[languageCode]!;
      print('EnhancedLanguageService: Current locale set to: ${_currentLocale.languageCode}');
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
        print('EnhancedLanguageService: Language preference saved to SharedPreferences');
      } catch (e) {
        print('Error saving language preference: $e');
      }
      
      // Clear translation cache to force fresh translations
      clearTranslationCache();
      
      print('EnhancedLanguageService: Notifying listeners of language change');
      notifyListeners();
      
      // Force immediate UI refresh
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
    } else {
      print('EnhancedLanguageService: Language $languageCode is not supported');
    }
  }
  
  String getCurrentLanguageCode() {
    return _currentLocale.languageCode;
  }
  
  String getLanguageName(String languageCode) {
    return LibreTranslateService.getLanguageName(languageCode);
  }
  
  List<String> getSupportedLanguageCodes() {
    return supportedLocales.keys.toList();
  }
  
  /// Get static translation for common UI elements
  String getStaticTranslation(String key) {
    final languageCode = getCurrentLanguageCode();
    
    final translations = _staticTranslations[languageCode] ?? _staticTranslations['en']!;
    final result = translations[key] ?? key;
    
    return result;
  }
  
  /// Translate dynamic text using API with immediate UI update
  Future<String> translateText(String text) async {
    if (text.isEmpty) return text;
    
    final languageCode = getCurrentLanguageCode();
    print('EnhancedLanguageService: Translating text: "$text" to language: $languageCode');
    
    if (languageCode == 'en') {
      print('EnhancedLanguageService: No translation needed for English');
      return text; // No translation needed for English
    }
    
    try {
      // Don't set loading state for individual text translations to avoid UI flicker
      String translatedText;
      if (_translationProvider == 'google') {
        print('EnhancedLanguageService: Using Google Translate');
        translatedText = await GoogleTranslateService.translateText(text, languageCode);
      } else {
        print('EnhancedLanguageService: Using LibreTranslate');
        translatedText = await LibreTranslateService.translateText(text, languageCode);
      }
      
      print('EnhancedLanguageService: Translation result: "$translatedText"');
      return translatedText;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }
  
  /// Translate multiple texts at once
  Future<Map<String, String>> translateMultiple(Map<String, String> texts) async {
    final languageCode = getCurrentLanguageCode();
    if (languageCode == 'en') return texts; // No translation needed for English
    
    try {
      _isLoading = true;
      notifyListeners();
      
      Map<String, String> translatedTexts;
      if (_translationProvider == 'google') {
        translatedTexts = await GoogleTranslateService.translateMultiple(texts, languageCode);
      } else {
        translatedTexts = await LibreTranslateService.translateMultiple(texts, languageCode);
      }
      
      _isLoading = false;
      notifyListeners();
      return translatedTexts;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Translation error: $e');
      return texts; // Return original texts if translation fails
    }
  }
  
  /// Set translation provider
  void setTranslationProvider(String provider) {
    if (provider == 'google' || provider == 'libre') {
      _translationProvider = provider;
      notifyListeners();
    }
  }
  
  /// Clear translation cache
  void clearTranslationCache() {
    if (_translationProvider == 'google') {
      GoogleTranslateService.clearCache();
    } else {
      LibreTranslateService.clearCache();
    }
  }
  
  /// Get cache size
  int getCacheSize() {
    if (_translationProvider == 'google') {
      return GoogleTranslateService.getCacheSize();
    } else {
      return LibreTranslateService.getCacheSize();
    }
  }
  
  /// Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return LibreTranslateService.isLanguageSupported(languageCode);
  }
  
  /// Get all supported languages
  Map<String, String> getSupportedLanguages() {
    return LibreTranslateService.getSupportedLanguages();
  }
} 