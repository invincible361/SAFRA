import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_language_service.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedLanguageService>(
      builder: (context, languageService, child) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          onSelected: (String languageCode) {
            languageService.setLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return languageService.getSupportedLanguageCodes().map((String languageCode) {
              return PopupMenuItem<String>(
                value: languageCode,
                child: Row(
                  children: [
                    Text(
                      languageService.getLanguageName(languageCode),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    if (languageService.getCurrentLanguageCode() == languageCode)
                      const Icon(Icons.check, size: 16),
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedLanguageService>(
      builder: (context, languageService, child) {
        return AlertDialog(
          title: Text(languageService.getStaticTranslation('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageService.getSupportedLanguageCodes().map((String languageCode) {
              final isSelected = languageService.getCurrentLanguageCode() == languageCode;
              return ListTile(
                title: Text(
                  languageService.getLanguageName(languageCode),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  languageService.setLanguage(languageCode);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageService.getStaticTranslation('cancel')),
            ),
          ],
        );
      },
    );
  }
}

class TranslationSettingsDialog extends StatelessWidget {
  const TranslationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedLanguageService>(
      builder: (context, languageService, child) {
        return AlertDialog(
          title: Text(languageService.getStaticTranslation('settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Translation Provider'),
                subtitle: Text(languageService.translationProvider == 'google' ? 'Google Translate' : 'LibreTranslate'),
                trailing: DropdownButton<String>(
                  value: languageService.translationProvider,
                  onChanged: (String? value) {
                    if (value != null) {
                      languageService.setTranslationProvider(value);
                    }
                  },
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
                ),
              ),
              ListTile(
                title: Text('Cache Size'),
                subtitle: Text('${languageService.getCacheSize()} translations cached'),
                trailing: TextButton(
                  onPressed: () {
                    languageService.clearTranslationCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Translation cache cleared')),
                    );
                  },
                  child: const Text('Clear Cache'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageService.getStaticTranslation('ok')),
            ),
          ],
        );
      },
    );
  }
} 