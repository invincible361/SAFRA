import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/oauth_config.dart';
import 'config/api_config.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/main_screen.dart' as main_screen;
import 'l10n/app_localizations.dart';
import 'services/enhanced_language_service.dart';
import 'dart:async';
import 'config/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables asynchronously without blocking
  _loadEnvironmentVariables();
  
  // Initialize Supabase immediately
  await Supabase.initialize(
    url: OAuthConfig.supabaseUrl,
    anonKey: OAuthConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

// Load environment variables in background
Future<void> _loadEnvironmentVariables() async {
  try {
    await dotenv.load(fileName: "assets/.env");
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      ApiConfig.setGoogleApiKey(apiKey);
    }
  } catch (e) {
    // Silent fail - API key can be loaded later when needed
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnhancedLanguageService()),
      ],
      child: Consumer<EnhancedLanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'SAFRA App',
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: AppColors.backgroundTop,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryAccent,
                brightness: Brightness.dark,
                primary: AppColors.primaryAccent,
                secondary: AppColors.secondaryAccent,
                surface: AppColors.surface,
                background: AppColors.backgroundTop,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(
                color: AppColors.cardBackground,
                elevation: 4,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('kn'),
            ],
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = true;
  Widget? _currentScreen;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Set up auth state listener
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        final userFullName = _getUserFullName(session.user);
        if (mounted) {
          setState(() {
            _currentScreen = main_screen.DashboardScreen(userFullName: userFullName);
            _isLoading = false;
          });
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _currentScreen = const LoginScreen();
            _isLoading = false;
          });
        }
      }
    });

    // Check current auth state immediately
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User is already authenticated
      final userFullName = _getUserFullName(session.user);
      setState(() {
        _currentScreen = main_screen.DashboardScreen(userFullName: userFullName);
        _isLoading = false;
      });
    } else {
      // No session, go to login page immediately
      if (mounted) {
        setState(() {
          _currentScreen = const LoginScreen();
          _isLoading = false;
        });
      }
    }
  }

  String _getUserFullName(User user) {
    // Try to get name from user metadata first
    final userMetadata = user.userMetadata;
    if (userMetadata != null) {
      final fullName = userMetadata['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
      
      // Try first_name and last_name
      final firstName = userMetadata['first_name'] as String? ?? '';
      final lastName = userMetadata['last_name'] as String? ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    
    // Fallback to email (extract name before @)
    if (user.email != null && user.email!.isNotEmpty) {
      final emailName = user.email!.split('@').first;
      // Convert email format to proper name (e.g., "aditya.jain" -> "Aditya Jain")
      return emailName.split('.').map((part) => 
        part.isNotEmpty ? '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}' : ''
      ).join(' ').trim();
    }
    
    // Final fallback
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return _currentScreen ?? const LoginScreen();
  }
}
