import 'package:flutter_test/flutter_test.dart';
import 'package:safra_app/services/translation_service.dart';

void main() {
  group('Language API Tests', () {
    test('LibreTranslate should translate text', () async {
      // Test basic translation
      final result = await LibreTranslateService.translateText('Hello', 'hi');
      expect(result, isNotEmpty);
      expect(result, isNot('Hello')); // Should be translated
      print('Translation result: $result');
    });

    test('Translation cache should work', () async {
      // Clear cache first
      LibreTranslateService.clearCache();
      expect(LibreTranslateService.getCacheSize(), 0);

      // First translation
      final result1 = await LibreTranslateService.translateText('Test', 'hi');
      expect(LibreTranslateService.getCacheSize(), 1);

      // Second translation (should use cache)
      final result2 = await LibreTranslateService.translateText('Test', 'hi');
      expect(result1, result2);
      expect(LibreTranslateService.getCacheSize(), 1); // Should still be 1
    });

    test('Empty text should return empty', () async {
      final result = await LibreTranslateService.translateText('', 'hi');
      expect(result, '');
    });

    test('English text should not be translated', () async {
      final result = await LibreTranslateService.translateText('Hello', 'en');
      expect(result, 'Hello');
    });

    test('Should handle API errors gracefully', () async {
      // Test with invalid language code
      final result = await LibreTranslateService.translateText('Hello', 'invalid');
      expect(result, 'Hello'); // Should return original text on error
    });
  });
} 