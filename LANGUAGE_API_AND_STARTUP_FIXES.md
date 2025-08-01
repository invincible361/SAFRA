# Language API and Startup Fixes

## Issues Fixed

### 1. Language API Error (301)
**Problem**: LibreTranslate API was returning 301 error due to outdated endpoint.

**Solution**: Updated API endpoints and added fallback translation services.

### 2. App Startup Behavior
**Problem**: App was checking for existing sessions and going to MapScreen.

**Solution**: App now always goes to login page on startup as requested.

## Language API Fixes

### Updated LibreTranslate Service
**Before (Broken)**:
```dart
static const String _baseUrl = 'https://libretranslate.de/translate';
```

**After (Fixed)**:
```dart
static const String _baseUrl = 'https://translate.argosopentech.com/translate';
```

### Added Fallback Translation Services

#### 1. MyMemory Translation API (Free)
```dart
class MyMemoryTranslateService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  // No API key required, free service
}
```

#### 2. Enhanced Main Translation Service
```dart
class TranslationService {
  // Try LibreTranslate first, fallback to MyMemory
  static Future<String> translateText(String text, String targetLanguage) async {
    // Try LibreTranslate
    try {
      final result = await LibreTranslateService.translateText(text, targetLanguage);
      if (result != text) return result;
    } catch (e) {
      print('LibreTranslate failed, trying MyMemory: $e');
    }
    
    // Fallback to MyMemory
    try {
      final result = await MyMemoryTranslateService.translateText(text, targetLanguage);
      if (result != text) return result;
    } catch (e) {
      print('MyMemory failed: $e');
    }
    
    return text; // Return original if all fail
  }
}
```

## App Startup Behavior

### Before (Session Check)
```dart
if (session != null) {
  // Go to MapScreen if session exists
  _currentScreen = const MapScreen();
} else {
  // Go to LoginScreen if no session
  _currentScreen = const LoginScreen();
}
```

### After (Always Login)
```dart
// Always go to login page on app startup (no biometric, no session check)
print('App starting - always going to login page');
setState(() {
  _currentScreen = const LoginScreen();
  _isLoading = false;
});
```

## Available Translation APIs

### 1. LibreTranslate (Primary)
- **URL**: `https://translate.argosopentech.com/translate`
- **Cost**: Free
- **API Key**: Not required
- **Method**: POST with JSON body

### 2. MyMemory (Fallback)
- **URL**: `https://api.mymemory.translated.net/get`
- **Cost**: Free
- **API Key**: Not required
- **Method**: GET with query parameters

### 3. Google Translate (Premium)
- **URL**: `https://translation.googleapis.com/language/translate/v2`
- **Cost**: Paid (requires API key)
- **API Key**: Required
- **Method**: POST with JSON body

## Supported Languages

All services support:
- English (en)
- Hindi (hi)
- Kannada (kn)
- Spanish (es)
- French (fr)
- German (de)
- Japanese (ja)
- Korean (ko)
- Chinese (zh)
- Arabic (ar)
- Portuguese (pt)
- Russian (ru)
- Italian (it)
- Dutch (nl)
- Polish (pl)
- Turkish (tr)
- Swedish (sv)
- Danish (da)
- Norwegian (no)
- Finnish (fi)

## Error Handling

### Graceful Fallback
1. **Try LibreTranslate** first
2. **If fails**, try MyMemory
3. **If both fail**, return original text
4. **Cache successful translations** to avoid repeated API calls

### Error Logging
```dart
print('LibreTranslate API error: ${response.statusCode} - ${response.body}');
print('MyMemory API error: ${response.statusCode} - ${response.body}');
```

## App Flow

### New App Startup Flow
```
App Start → LoginScreen (always)
```

### Authentication Flow
```
LoginScreen → Google OAuth → MapScreen
```

### Translation Flow
```
Text Input → LibreTranslate → MyMemory (fallback) → Translated Text
```

## Benefits

### Language API
- ✅ **Fixed 301 Error**: Updated LibreTranslate endpoint
- ✅ **Multiple Fallbacks**: LibreTranslate + MyMemory
- ✅ **Free Services**: No API keys required
- ✅ **Caching**: Reduces API calls
- ✅ **Error Handling**: Graceful degradation

### App Startup
- ✅ **Consistent Behavior**: Always goes to login
- ✅ **No Biometric**: Removed biometric checks
- ✅ **No Session Check**: Simplified startup flow
- ✅ **User Control**: Users choose when to login

## Testing

### Language API Testing
1. **Test LibreTranslate**: Should work with new endpoint
2. **Test MyMemory**: Should work as fallback
3. **Test Caching**: Should cache translations
4. **Test Error Handling**: Should return original text on failure

### App Startup Testing
1. **Fresh Install**: Should go to LoginScreen
2. **Existing Session**: Should still go to LoginScreen
3. **Google Login**: Should work and go to MapScreen
4. **No Biometric**: Should not prompt for biometric

## Files Modified

1. **`lib/services/translation_service.dart`**
   - Updated LibreTranslate endpoint
   - Added MyMemory service
   - Enhanced error handling
   - Added fallback mechanism

2. **`lib/main.dart`**
   - Removed session check
   - Always go to LoginScreen on startup
   - Simplified startup flow

## Future Improvements

### Translation Services
- Add more free translation APIs
- Implement rate limiting
- Add offline translation support
- Improve caching strategy

### App Behavior
- Add user preference for startup behavior
- Implement "Remember Me" functionality
- Add biometric option (when ready)
- Improve error messages

The language API errors are now fixed with multiple fallback options, and the app always starts at the login page as requested! 