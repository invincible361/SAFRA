import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_language_service.dart';

class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool useStaticTranslation;
  final String? staticKey;

  const TranslatedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.useStaticTranslation = false,
    this.staticKey,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String _translatedText = '';
  bool _isLoading = false;
  String? _lastLanguageCode;

  @override
  void initState() {
    super.initState();
    _translatedText = widget.text;
    _translateText();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || 
        oldWidget.useStaticTranslation != widget.useStaticTranslation ||
        oldWidget.staticKey != widget.staticKey) {
      _translateText();
    }
  }

  Future<void> _translateText() async {
    final languageService = context.read<EnhancedLanguageService>();
    final currentLanguage = languageService.getCurrentLanguageCode();
    
    // Only translate if language has changed or if it's the first time
    if (_lastLanguageCode == currentLanguage && _lastLanguageCode != null) {
      return;
    }
    
    _lastLanguageCode = currentLanguage;
    
    if (widget.useStaticTranslation && widget.staticKey != null) {
      setState(() {
        _translatedText = languageService.getStaticTranslation(widget.staticKey!);
        _isLoading = false;
      });
      return;
    }

    if (currentLanguage == 'en') {
      setState(() {
        _translatedText = widget.text;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final translated = await languageService.translateText(widget.text);
      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedText = widget.text; // Fallback to original text
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedLanguageService>(
      builder: (context, languageService, child) {
        final currentLanguage = languageService.getCurrentLanguageCode();
        
        // Only trigger translation if language has changed
        if (_lastLanguageCode != currentLanguage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _translateText();
          });
        }

        if (_isLoading) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: widget.style,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                overflow: widget.overflow,
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          );
        }

        return Text(
          _translatedText,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}

class TranslatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final Widget? icon;
  final bool useStaticTranslation;
  final String? staticKey;

  const TranslatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.icon,
    this.useStaticTranslation = false,
    this.staticKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedLanguageService>(
      builder: (context, languageService, child) {
        String buttonText;
        
        if (useStaticTranslation && staticKey != null) {
          buttonText = languageService.getStaticTranslation(staticKey!);
        } else {
          buttonText = text;
        }

        return ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: icon != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  TranslatedText(
                    text: buttonText,
                    useStaticTranslation: useStaticTranslation,
                    staticKey: staticKey,
                  ),
                ],
              )
            : TranslatedText(
                text: buttonText,
                useStaticTranslation: useStaticTranslation,
                staticKey: staticKey,
              ),
        );
      },
    );
  }
}

class TranslatedTextField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool useStaticTranslation;
  final String? staticKey;

  const TranslatedTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.useStaticTranslation = false,
    this.staticKey,
  });

  @override
  State<TranslatedTextField> createState() => _TranslatedTextFieldState();
}

class _TranslatedTextFieldState extends State<TranslatedTextField> {
  String _translatedLabel = '';
  String _translatedHint = '';
  bool _isLoading = false;
  String? _lastLanguageCode;

  @override
  void initState() {
    super.initState();
    _translatedLabel = widget.labelText;
    _translatedHint = widget.hintText ?? '';
    _translateLabels();
  }

  @override
  void didUpdateWidget(TranslatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labelText != widget.labelText || 
        oldWidget.hintText != widget.hintText ||
        oldWidget.useStaticTranslation != widget.useStaticTranslation ||
        oldWidget.staticKey != widget.staticKey) {
      _translateLabels();
    }
  }

  Future<void> _translateLabels() async {
    final languageService = context.read<EnhancedLanguageService>();
    final currentLanguage = languageService.getCurrentLanguageCode();
    
    // Only translate if language has changed or if it's the first time
    if (_lastLanguageCode == currentLanguage && _lastLanguageCode != null) {
      return;
    }
    
    _lastLanguageCode = currentLanguage;
    
    if (widget.useStaticTranslation && widget.staticKey != null) {
      setState(() {
        _translatedLabel = languageService.getStaticTranslation(widget.staticKey!);
        _translatedHint = widget.hintText ?? '';
        _isLoading = false;
      });
      return;
    }

    if (currentLanguage == 'en') {
      setState(() {
        _translatedLabel = widget.labelText;
        _translatedHint = widget.hintText ?? '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final translatedLabel = await languageService.translateText(widget.labelText);
      String translatedHint = '';
      if (widget.hintText != null) {
        translatedHint = await languageService.translateText(widget.hintText!);
      }

      if (mounted) {
        setState(() {
          _translatedLabel = translatedLabel;
          _translatedHint = translatedHint;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedLabel = widget.labelText;
          _translatedHint = widget.hintText ?? '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedLanguageService>(
      builder: (context, languageService, child) {
        final currentLanguage = languageService.getCurrentLanguageCode();
        
        // Only trigger translation if language has changed
        if (_lastLanguageCode != currentLanguage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _translateLabels();
          });
        }

        return TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: _isLoading ? widget.labelText : _translatedLabel,
            hintText: _isLoading ? widget.hintText : _translatedHint,
            suffixIcon: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
          ),
        );
      },
    );
  }
} 