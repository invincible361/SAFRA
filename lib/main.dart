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
  final bool _biometricChecked = false;
  int _screenRebuildKey = 0; // Add a key to force rebuilds
  bool _forceRebuild = false; // Add flag to force complete rebuild

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
    // Set up auth state listener (but don't wait for it)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      
      // Handle auth state changes efficiently
      if (event == AuthChangeEvent.signedIn && session != null) {
        AppLifecycleService().setAuthenticated(true);
        final userFullName = _getUserFullName(session.user);
        _forceNavigateToDashboard(userFullName);
      } else if (event == AuthChangeEvent.signedOut) {
        // Quick check for OAuth completion without delay
        final currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession != null) {
          AppLifecycleService().setAuthenticated(true);
          final userFullName = _getUserFullName(currentSession.user);
          _forceNavigateToDashboard(userFullName);
        } else {
          AppLifecycleService().setAuthenticated(false);
          if (mounted) {
            setState(() {
              _currentScreen = const LoginScreen();
              _isLoading = false;
              _screenRebuildKey++;
            });
          }
        }
      } else if ((event == AuthChangeEvent.tokenRefreshed || event == AuthChangeEvent.userUpdated) && session != null) {
        AppLifecycleService().setAuthenticated(true);
        if (mounted && _currentScreen is! DashboardScreen) {
          final userFullName = _getUserFullName(session.user);
          setState(() {
            _currentScreen = DashboardScreen(userFullName: userFullName);
            _isLoading = false;
          });
        }
      }
    });

    // Check current auth state immediately
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User is already authenticated
      AppLifecycleService().setAuthenticated(true);
      // Use immediate navigation without biometric check for faster startup
      final userFullName = _getUserFullName(session.user);
      setState(() {
        _currentScreen = DashboardScreen(userFullName: userFullName);
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

  Future<void> _checkStartupBiometric() async {
    try {
      print('Main: Checking if startup biometric authentication is needed...');
      
      // Get current session and user
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        print('Main: No session found, redirecting to login');
        if (mounted) {
          setState(() {
            _currentScreen = const LoginScreen();
            _isLoading = false;
          });
        }
        return;
      }
      
      final userFullName = _getUserFullName(session.user);
      final isSecurityEnabled = await BiometricService.isSecurityEnabled();
      
      if (isSecurityEnabled) {
        print('Main: Security enabled, triggering startup biometric check');
        await _handleBiometricAuthentication();
        
        // If biometric succeeds, go to dashboard screen
        if (mounted) {
          setState(() {
            _currentScreen = DashboardScreen(userFullName: userFullName);
            _isLoading = false;
          });
          print('Successfully set current screen to DashboardScreen after biometric check');
        }
      } else {
        // No security enabled, go directly to dashboard screen
        print('Main: No security enabled, going directly to dashboard screen');
        if (mounted) {
          setState(() {
            _currentScreen = DashboardScreen(userFullName: userFullName);
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
          final session = Supabase.instance.client.auth.currentSession;
          final userFullName = session != null ? _getUserFullName(session.user) : 'User';
          _currentScreen = DashboardScreen(userFullName: userFullName);
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
      
      // Get current session and user
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        print('No session found, redirecting to login');
        if (mounted) {
          setState(() {
            _currentScreen = const LoginScreen();
            _isLoading = false;
          });
        }
        return;
      }
      
      final userFullName = _getUserFullName(session.user);
      
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
            _currentScreen = DashboardScreen(userFullName: userFullName);
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
        final session = Supabase.instance.client.auth.currentSession;
        final userFullName = session != null ? _getUserFullName(session.user) : 'User';
        setState(() {
          _currentScreen = DashboardScreen(userFullName: userFullName);
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
      final userFullName = _getUserFullName(session.user);
      setState(() {
        _currentScreen = DashboardScreen(userFullName: userFullName);
        _isLoading = false;
        _screenRebuildKey++;
      });
    } else if (mounted) {
      print('Manual auth check - No session, staying on login');
      setState(() {
        _currentScreen = const LoginScreen();
        _isLoading = false;
        _screenRebuildKey++;
      });
    }
  }
  
  // Simplified force navigation - immediate and efficient
  void _forceNavigateToDashboard(String userFullName) {
    if (mounted) {
      print('Force navigating to dashboard with user: $userFullName');
      
      // Single, immediate navigation without delays
      setState(() {
        _currentScreen = DashboardScreen(userFullName: userFullName);
        _isLoading = false;
        _screenRebuildKey++; // Single increment is sufficient
        _forceRebuild = false; // Reset immediately
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Main build method called - _isLoading: $_isLoading, _currentScreen: ${_currentScreen?.runtimeType}, key: $_screenRebuildKey, forceRebuild: $_forceRebuild');
    
    if (_isLoading) {
      return Scaffold(
        key: ValueKey('loading_screen_$_screenRebuildKey'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Return the current screen or login screen as fallback
    // Use the rebuild key to force complete widget recreation
    if (_currentScreen != null) {
      print('Building screen: ${_currentScreen.runtimeType} with key: $_screenRebuildKey');
      return KeyedSubtree(
        key: ValueKey('screen_${_currentScreen.runtimeType}_$_screenRebuildKey${_forceRebuild ? 'force' : 'normal'}'),
        child: _currentScreen!,
      );
    }
    
    print('Building fallback LoginScreen with key: $_screenRebuildKey');
    return KeyedSubtree(
      key: ValueKey('login_screen_$_screenRebuildKey${_forceRebuild ? 'force' : 'normal'}'),
      child: const LoginScreen(),
    );
  }
}
