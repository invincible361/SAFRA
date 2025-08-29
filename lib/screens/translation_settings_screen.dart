import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_language_service.dart';
import '../widgets/translated_text.dart';

class TranslationSettingsScreen extends StatelessWidget {
  const TranslationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          text: 'Translation Settings',
          useStaticTranslation: true,
          staticKey: 'settings',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<EnhancedLanguageService>(
        builder: (context, languageService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          text: 'Language',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: languageService.getCurrentLanguageCode(),
                          decoration: const InputDecoration(
                            labelText: 'Select Language',
                            border: OutlineInputBorder(),
                          ),
                          items: languageService.getSupportedLanguageCodes().map((String code) {
                            return DropdownMenuItem<String>(
                              value: code,
                              child: Text(languageService.getLanguageName(code)),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              languageService.setLanguage(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Translation Provider
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          text: 'Translation Provider',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: languageService.translationProvider,
                          decoration: const InputDecoration(
                            labelText: 'Select Provider',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'libre',
                              child: Text('LibreTranslate (Free)'),
                            ),
                            DropdownMenuItem(
                              value: 'google',
                              child: Text('Google Translate (Paid)'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              languageService.setTranslationProvider(value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageService.translationProvider == 'google'
                              ? 'Google Translate provides high-quality translations but requires an API key'
                              : 'LibreTranslate is free and open-source but may have limited language support',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Cache Management
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          text: 'Translation Cache',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cached translations: ${languageService.getCacheSize()}'),
                            ElevatedButton(
                              onPressed: () {
                                languageService.clearTranslationCache();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Translation cache cleared'),
                                  ),
                                );
                              },
                              child: const Text('Clear Cache'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Translation Test
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          text: 'Test Translation',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const TranslationTestWidget(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          text: 'Information',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '• Static translations are used for common UI elements\n'
                          '• Dynamic content is translated using the selected API\n'
                          '• Translations are cached to improve performance\n'
                          '• You can switch between translation providers\n'
                          '• Some languages may not be supported by all providers',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TranslationTestWidget extends StatefulWidget {
  const TranslationTestWidget({super.key});

  @override
  State<TranslationTestWidget> createState() => _TranslationTestWidgetState();
}

class _TranslationTestWidgetState extends State<TranslationTestWidget> {
  final TextEditingController _testController = TextEditingController();
  String _translatedText = '';
  bool _isTranslating = false;

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  Future<void> _testTranslation() async {
    if (_testController.text.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final languageService = context.read<EnhancedLanguageService>();
      final translated = await languageService.translateText(_testController.text);
      
      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedText = 'Translation failed: $e';
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _testController,
          decoration: const InputDecoration(
            labelText: 'Enter text to translate',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isTranslating ? null : _testTranslation,
          child: _isTranslating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Translate'),
        ),
        if (_translatedText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Translation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_translatedText),
              ],
            ),
          ),
        ],
      ],
    );
  }
} 