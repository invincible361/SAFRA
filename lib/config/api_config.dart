import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get googleMapsApiKey {
    try {
      final key = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      print("Error accessing environment variables: $e");
    }
    
    // Fallback to hardcoded key for development
    // TODO: Remove this in production
    print("Warning: Using fallback API key. Please configure assets/.env file");
    return 'AIzaSyA1nhqmZMTFmqktFcJML_6WR5PDFGqH6N8';
  }
} 