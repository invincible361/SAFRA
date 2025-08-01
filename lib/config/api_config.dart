import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _cachedGoogleApiKey;
  static String? _cachedOpenAiApiKey;
  
  static String get googleMapsApiKey {
    // Return cached key if available
    if (_cachedGoogleApiKey != null) {
      return _cachedGoogleApiKey!;
    }
    
    try {
      final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (key != null && key.isNotEmpty) {
        _cachedGoogleApiKey = key;
        return key;
      }
    } catch (e) {
      print("Error accessing environment variables: $e");
    }
    
    // Fallback to hardcoded key for development
    // TODO: Remove this in production
    print("Warning: Using fallback Google API key. Please configure assets/.env file");
    _cachedGoogleApiKey = 'AIzaSyA1nhqmZMTFmqktFcJML_6WR5PDFGqH6N8';
    return _cachedGoogleApiKey!;
  }

  static String get openAiApiKey {
    // Return cached key if available
    if (_cachedOpenAiApiKey != null) {
      return _cachedOpenAiApiKey!;
    }
    
    try {
      final key = dotenv.env['OPENAI_API_KEY'];
      if (key != null && key.isNotEmpty) {
        _cachedOpenAiApiKey = key;
        return key;
      }
    } catch (e) {
      print("Error accessing environment variables: $e");
    }
    
    // Fallback for development
    print("Warning: OpenAI API key not configured. AI features will use fallback analysis.");
    _cachedOpenAiApiKey = 'your-openai-api-key';
    return _cachedOpenAiApiKey!;
  }
  
  static void setGoogleApiKey(String key) {
    _cachedGoogleApiKey = key;
  }

  static void setOpenAiApiKey(String key) {
    _cachedOpenAiApiKey = key;
  }
} 