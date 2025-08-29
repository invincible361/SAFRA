import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/map_screen.dart';
import 'screens/main_screen.dart';
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
import 'config/app_colors.dart';

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
      
      // Handle all possible OAuth events
      if (event == AuthChangeEvent.signedIn && session != null) {
        // User is signed in, set authenticated state and go to dashboard screen (no biometric check)
        print('User signed in, setting authenticated state and navigating to dashboard screen');
        AppLifecycleService().setAuthenticated(true);
        if (mounted) {
          setState(() {
            _currentScreen = const DashboardScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to DashboardScreen');
        } else {
          print('Widget not mounted when trying to navigate to DashboardScreen');
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
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        // Token refreshed, user is still authenticated
        print('Token refreshed, user remains authenticated');
        AppLifecycleService().setAuthenticated(true);
        if (mounted && _currentScreen is! DashboardScreen) {
          setState(() {
            _currentScreen = const DashboardScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to DashboardScreen after token refresh');
        }
      } else if (event == AuthChangeEvent.userUpdated && session != null) {
        // User updated, still authenticated
        print('User updated, user remains authenticated');
        AppLifecycleService().setAuthenticated(true);
        if (mounted && _currentScreen is! DashboardScreen) {
          setState(() {
            _currentScreen = const DashboardScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to DashboardScreen after user update');
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
      
      // User is already authenticated, check if biometric security is needed
      AppLifecycleService().setAuthenticated(true);
      await _checkStartupBiometric();
    } else {
      // No session, go to login page
      print('App starting - no session, going to login page');
      if (mounted) {
        setState(() {
          _currentScreen = const LoginScreen();
          _isLoading = false;
        });
        print('Successfully set current screen to LoginScreen (app startup)');
      }
    }
  }

  Future<void> _checkStartupBiometric() async {
    try {
      print('Main: Checking if startup biometric authentication is needed...');
      
      final isSecurityEnabled = await BiometricService.isSecurityEnabled();
      if (isSecurityEnabled) {
        print('Main: Security enabled, triggering startup biometric check');
        await _handleBiometricAuthentication();
        
        // If biometric succeeds, go to dashboard screen
        if (mounted) {
          setState(() {
            _currentScreen = const DashboardScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to DashboardScreen after biometric check');
        }
      } else {
        // No security enabled, go directly to dashboard screen
        print('Main: No security enabled, going directly to dashboard screen');
        if (mounted) {
          setState(() {
            _currentScreen = const DashboardScreen();
            _isLoading = false;
          });
          print('Successfully set current screen to DashboardScreen (no security)');
        }
      }
    } catch (e) {
      print('Main: Error during startup biometric check: $e');
      // On error, go to dashboard screen (user is authenticated)
      if (mounted) {
        setState(() {
          _currentScreen = const DashboardScreen();
          _isLoading = false;
        });
      }
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
      print('Main: App resumed, checking if biometric authentication is needed');
      
      // Check if we need to show biometric authentication
      final isSecurityEnabled = await BiometricService.isSecurityEnabled();
      if (isSecurityEnabled && AppLifecycleService().wasSuspended && AppLifecycleService().isAuthenticated) {
        print('Main: Security enabled and app was suspended while authenticated, triggering biometric check');
        await _handleBiometricAuthentication();
      }
    } catch (e) {
      print('Error in _handleAppResumed: $e');
    }
  }

  Future<void> _handleBiometricAuthentication() async {
    try {
      print('Main: Handling biometric authentication...');
      
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      final pinSet = await BiometricService.isPinSet();
      
      if (biometricEnabled) {
        // Try biometric authentication
        print('Main: Attempting biometric authentication...');
        final success = await BiometricService.authenticateWithBiometric();
        
        if (success) {
          print('Main: Biometric authentication successful');
          // User can continue using the app
        } else {
          print('Main: Biometric authentication failed, redirecting to login');
          _redirectToLogin();
        }
      } else if (pinSet) {
        // Show PIN authentication dialog
        print('Main: Showing PIN authentication dialog');
        _showPinAuthenticationDialog();
      } else {
        print('Main: No security method available');
      }
    } catch (e) {
      print('Main: Error during biometric authentication: $e');
      _redirectToLogin();
    }
  }

  void _showPinAuthenticationDialog() {
    if (!mounted) return;
    
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // User must authenticate to continue
      builder: (context) => AlertDialog(
        title: const Text('Security Check Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your PIN to continue using the app.'),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final enteredPin = pinController.text;
              if (enteredPin.isNotEmpty) {
                final success = await BiometricService.authenticateWithPin(enteredPin);
                if (success) {
                  Navigator.pop(context);
                  print('Main: PIN authentication successful');
                } else {
                  // Show error and keep dialog open
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect PIN. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;
    
    print('Main: Redirecting to login screen');
    setState(() {
      _currentScreen = const LoginScreen();
    });
    
    // Clear authentication state
    AppLifecycleService().setAuthenticated(false);
    
    // Sign out the user
    Supabase.instance.client.auth.signOut();
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
          // No security enabled, go directly to dashboard screen (user is already authenticated)
          print('No security enabled, going directly to dashboard screen');
          setState(() {
            _currentScreen = const DashboardScreen();
            _isLoading = false;
          });
        }
      } else {
        print('Widget not mounted in _checkBiometricAndNavigate');
      }
    } catch (e) {
      print('Error in _checkBiometricAndNavigate: $e');
      // If there's an error, go to dashboard screen (user is authenticated)
      if (mounted) {
        setState(() {
          _currentScreen = const DashboardScreen();
          _isLoading = false;
        });
      }
    }
  }

  // Add a method to manually check auth state and navigate
  void _checkAuthStateAndNavigate() {
    final session = Supabase.instance.client.auth.currentSession;
    print('Manual auth check - Session: ${session != null ? "exists" : "null"}');
    
    if (session != null && mounted) {
      print('Manual auth check - User authenticated, navigating to dashboard');
      AppLifecycleService().setAuthenticated(true);
      setState(() {
        _currentScreen = const DashboardScreen();
        _isLoading = false;
      });
    } else if (mounted) {
      print('Manual auth check - No session, staying on login');
      setState(() {
        _currentScreen = const LoginScreen();
        _isLoading = false;
      });
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
