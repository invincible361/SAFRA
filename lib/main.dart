import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/map_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/oauth_config.dart';
import 'l10n/app_localizations.dart';
import 'services/biometric_service.dart';
import 'services/app_lifecycle_service.dart';
import 'services/enhanced_language_service.dart';
import 'dart:async';

// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
    print("Successfully loaded .env file");
    // Test if we can access the API key
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      print("API key loaded successfully: ${apiKey.substring(0, 10)}...");
      ApiConfig.setGoogleApiKey(apiKey);
    } else {
      print("Warning: API key is empty or null");
    }
  } catch (e) {
    print("Warning: Could not load .env file: $e");
    print("Make sure to create a .env file in the assets folder");
  }
  
  await Supabase.initialize(
    url: OAuthConfig.supabaseUrl,
    anonKey: OAuthConfig.supabaseAnonKey,
  );
  runApp(const MyApp());
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
            navigatorKey: navigatorKey, // Use global navigator key
            title: 'SAFRA App',
            debugShowCheckedModeBanner: false,
            locale: languageService.currentLocale,
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF111416),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFCAE3F2),
                brightness: Brightness.dark,
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

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = true;
  Widget? _currentScreen;
  bool _biometricChecked = false;

  @override
  void initState() {
    super.initState();
    // Initialize app lifecycle service
    AppLifecycleService().initialize(context);
    // Add observer for lifecycle events
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Always listen for auth changes first
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      print('**** onAuthStateChange: $event');
      print('Session data: ${session != null ? session.toJson() : "null"}');
      print('Current user: ${session?.user?.email ?? "no user"}');
      print('User ID: ${session?.user?.id ?? "no id"}');
      print('Event type: ${event.runtimeType}');
      print('Is signed in event: ${event == AuthChangeEvent.signedIn}');
      print('Is session not null: ${session != null}');
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // User is signed in, set authenticated state and go to map screen (no biometric check)
        print('User signed in, setting authenticated state and navigating to map screen');
        AppLifecycleService().setAuthenticated(true);
        if (mounted) {
          setState(() {
            _currentScreen = const MapScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to MapScreen');
        } else {
          print('Widget not mounted when trying to navigate to MapScreen');
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // User signed out, clear authenticated state and go to login
        print('User signed out, clearing authenticated state and navigating to login screen');
        AppLifecycleService().setAuthenticated(false);
        if (mounted) {
          setState(() {
            _currentScreen = const LoginScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to LoginScreen');
        } else {
          print('Widget not mounted when trying to navigate to LoginScreen');
        }
      } else {
        print('Auth state change not handled - event: $event, session: ${session != null ? "exists" : "null"}');
        print('Condition check: event == AuthChangeEvent.signedIn: ${event == AuthChangeEvent.signedIn}');
        print('Condition check: session != null: ${session != null}');
      }
    });

    print('Auth state listener set up successfully');
    
    // Test the auth state listener by checking current session
    final testSession = Supabase.instance.client.auth.currentSession;
    print('Test: Current session check: ${testSession != null ? "exists" : "null"}');
    
    // Check current auth state
    final session = Supabase.instance.client.auth.currentSession;
    print('Current session on app start: ${session != null ? "exists" : "null"}');
    if (session != null) {
      print('Session user email: ${session.user?.email ?? "no email"}');
      print('Session user ID: ${session.user?.id ?? "no id"}');
    }
    
    // Always go to login page on app startup (no biometric, no session check)
    print('App starting - always going to login page');
    if (mounted) {
      setState(() {
        _currentScreen = const LoginScreen();
        _isLoading = false;
      });
      print('Successfully set current screen to LoginScreen (app startup)');
    } else {
      print('Widget not mounted when trying to set LoginScreen (app startup)');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    try {
      print('Main: App resumed, letting AppLifecycleService handle biometric check');
      // AppLifecycleService will handle biometric check if needed
    } catch (e) {
      print('Error in _handleAppResumed: $e');
    }
  }

  Future<void> _checkBiometricAndNavigate() async {
    try {
      print('Checking biometric security...');
      
      // Check if biometric security is enabled
      final isSecurityEnabled = await BiometricService.isSecurityEnabled();
      print('Security enabled: $isSecurityEnabled');
      
      if (mounted) {
        if (isSecurityEnabled) {
          // Security is enabled, show auth screen for biometric verification
          print('Security enabled, showing AuthScreen for biometric verification');
          setState(() {
            _currentScreen = const AuthScreen();
            _isLoading = false;
          });
        } else {
          // No security enabled, go directly to map screen (user is already authenticated)
          print('No security enabled, going directly to map screen');
          setState(() {
            _currentScreen = const MapScreen();
            _isLoading = false;
          });
        }
      } else {
        print('Widget not mounted in _checkBiometricAndNavigate');
      }
    } catch (e) {
      print('Error in _checkBiometricAndNavigate: $e');
      // If there's an error, go to map screen (user is authenticated)
      if (mounted) {
        setState(() {
          _currentScreen = const MapScreen();
          _isLoading = false;
        });
      }
    }
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
    
    // Return the current screen or login screen as fallback
    return _currentScreen ?? const LoginScreen();
  }
}
