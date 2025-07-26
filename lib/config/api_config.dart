import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String? _cachedApiKey;
  
  static String get googleMapsApiKey {
    // Return cached key if available
    if (_cachedApiKey != null) {
      return _cachedApiKey!;
    }
    
    try {
      final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (key != null && key.isNotEmpty) {
        _cachedApiKey = key;
        return key;
      }
    } catch (e) {
      print("Error accessing environment variables: $e");
    }
    
    // Fallback to hardcoded key for development
    // TODO: Remove this in production
    print("Warning: Using fallback API key. Please configure assets/.env file");
    _cachedApiKey = 'AIzaSyA1nhqmZMTFmqktFcJML_6WR5PDFGqH6N8';
    return _cachedApiKey!;
  }
  
  static void setApiKey(String key) {
    _cachedApiKey = key;
  }
} 