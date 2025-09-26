import 'dart:convert';
import 'package:http/http.dart' as http;

// LibreTranslate service (free alternative) - Updated with working endpoints
class LibreTranslateService {
  // Updated base URL to fix 301 error
  static const String _baseUrl = 'https://translate.argosopentech.com/translate';
  
  static final Map<String, String> _translationCache = {};
  
  // Simplified to only Hindi, English, and Kannada
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'kn': 'Kannada',
  };

  static Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;
    
    // Check cache first
    final cacheKey = '${text}_$targetLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'source': 'auto',
          'target': targetLanguage,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['translatedText'];
        
        // Cache the translation
        _translationCache[cacheKey] = translatedText;
        
        return translatedText;
      } else {
        print('LibreTranslate API error: ${response.statusCode} - ${response.body}');
        return text;
      }
    } catch (e) {
      print('LibreTranslate error: $e');
      return text;
    }
  }

  /// Translate multiple texts at once
  static Future<Map<String, String>> translateMultiple(
    Map<String, String> texts,
    String targetLanguage,
  ) async {
    final Map<String, String> results = {};
    
    for (final entry in texts.entries) {
      final translated = await translateText(entry.value, targetLanguage);
      results[entry.key] = translated;
    }
    
    return results;
  }

  static Map<String, String> getSupportedLanguages() {
    return Map.from(supportedLanguages);
  }

  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  static void clearCache() {
    _translationCache.clear();
  }

  static int getCacheSize() {
    return _translationCache.length;
  }
}

// Alternative: MyMemory Translation API (free, no API key required)
class MyMemoryTranslateService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  
  static final Map<String, String> _translationCache = {};
  
  // Simplified to only Hindi, English, and Kannada
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'kn': 'Kannada',
  };

  static Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;
    
    // Check cache first
    final cacheKey = '${text}_$targetLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=en|$targetLanguage'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['responseData']['translatedText'];
        
        // Cache the translation
        _translationCache[cacheKey] = translatedText;
        
        return translatedText;
      } else {
        print('MyMemory API error: ${response.statusCode} - ${response.body}');
        return text;
      }
    } catch (e) {
      print('MyMemory error: $e');
      return text;
    }
  }

  /// Translate multiple texts at once
  static Future<Map<String, String>> translateMultiple(
    Map<String, String> texts,
    String targetLanguage,
  ) async {
    final Map<String, String> results = {};
    
    for (final entry in texts.entries) {
      final translated = await translateText(entry.value, targetLanguage);
      results[entry.key] = translated;
    }
    
    return results;
  }

  static Map<String, String> getSupportedLanguages() {
    return Map.from(supportedLanguages);
  }

  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  static void clearCache() {
    _translationCache.clear();
  }

  static int getCacheSize() {
    return _translationCache.length;
  }
}

// Alternative: Using Google Translate API (requires API key)
class GoogleTranslateService {
  static const String _apiKey = 'YOUR_GOOGLE_TRANSLATE_API_KEY'; // Replace with your API key
  static const String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';
  
  static final Map<String, String> _translationCache = {};
  
  // Simplified to only Hindi, English, and Kannada
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'kn': 'Kannada',
  };

  static Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;
    
    // Check cache first
    final cacheKey = '${text}_$targetLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'target': targetLanguage,
          'format': 'text',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['data']['translations'][0]['translatedText'];
        
        // Cache the translation
        _translationCache[cacheKey] = translatedText;
        
        return translatedText;
      } else {
        print('Google Translate API error: ${response.statusCode} - ${response.body}');
        return text;
      }
    } catch (e) {
      print('Google Translate error: $e');
      return text;
    }
  }

  /// Translate multiple texts at once
  static Future<Map<String, String>> translateMultiple(
    Map<String, String> texts,
    String targetLanguage,
  ) async {
    final Map<String, String> results = {};
    
    for (final entry in texts.entries) {
      final translated = await translateText(entry.value, targetLanguage);
      results[entry.key] = translated;
    }
    
    return results;
  }

  static Map<String, String> getSupportedLanguages() {
    return Map.from(supportedLanguages);
  }

  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  static void clearCache() {
    _translationCache.clear();
  }

  static int getCacheSize() {
    return _translationCache.length;
  }
}

// Main Translation Service - Default to LibreTranslate with fallback
class TranslationService {
  static final Map<String, String> _translationCache = {};
  
  // Simplified to only Hindi, English, and Kannada
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'Hindi',
    'kn': 'Kannada',
  };

  /// Translate text to target language with fallback
  static Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;
    
    // Check cache first
    final cacheKey = '${text}_$targetLanguage';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }
    
    // Try LibreTranslate first
    try {
      final result = await LibreTranslateService.translateText(text, targetLanguage);
      if (result != text) {
        _translationCache[cacheKey] = result;
        return result;
      }
    } catch (e) {
      print('LibreTranslate failed, trying MyMemory: $e');
    }
    
    // Fallback to MyMemory
    try {
      final result = await MyMemoryTranslateService.translateText(text, targetLanguage);
      if (result != text) {
        _translationCache[cacheKey] = result;
        return result;
      }
    } catch (e) {
      print('MyMemory failed: $e');
    }
    
    // Return original text if all translation services fail
    return text;
  }

  /// Translate multiple texts at once
  static Future<Map<String, String>> translateMultiple(
    Map<String, String> texts,
    String targetLanguage,
  ) async {
    final Map<String, String> results = {};
    
    for (final entry in texts.entries) {
      final translated = await translateText(entry.value, targetLanguage);
      results[entry.key] = translated;
    }
    
    return results;
  }

  /// Get supported languages
  static Map<String, String> getSupportedLanguages() {
    return Map.from(supportedLanguages);
  }

  /// Check if language is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  /// Get language name by code
  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  /// Clear translation cache
  static void clearCache() {
    _translationCache.clear();
  }

  /// Get cached translations count
  static int getCacheSize() {
    return _translationCache.length;
  }
} 