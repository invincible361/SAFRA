import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../services/app_lifecycle_service.dart';
import 'map_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinSet = false;
  String? _currentSecurityMethod;
  final TextEditingController _pinController = TextEditingController();
  bool _showPinInput = false;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    try {
      print('AuthScreen: Checking security status...');
      
      final biometricAvailable = await BiometricService.isBiometricAvailable();
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      final pinSet = await BiometricService.isPinSet();
      final currentMethod = await BiometricService.getCurrentSecurityMethod();

      print('AuthScreen: Biometric available: $biometricAvailable');
      print('AuthScreen: Biometric enabled: $biometricEnabled');
      print('AuthScreen: PIN set: $pinSet');
      print('AuthScreen: Current method: $currentMethod');

      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _pinSet = pinSet;
        _currentSecurityMethod = currentMethod;
        _isLoading = false;
      });

      // If no security is enabled, go directly to map screen
      if (!biometricEnabled && !pinSet) {
        print('AuthScreen: No security enabled, navigating to map');
        _navigateToMap();
        return;
      }

      // If biometric is enabled and available, try to authenticate automatically
      if (biometricEnabled && biometricAvailable) {
        print('AuthScreen: Attempting automatic biometric authentication');
        // Add a small delay to let the UI settle
        await Future.delayed(const Duration(milliseconds: 500));
        _authenticateWithBiometric();
      } else if (pinSet && !biometricEnabled) {
        // Only PIN is available, show PIN input
        print('AuthScreen: Only PIN available, showing PIN input');
        setState(() {
          _showPinInput = true;
        });
      }
    } catch (e) {
      print('AuthScreen: Error checking security status: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error checking security settings: $e';
      });
      // If there's an error, go to map screen after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToMap();
        }
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return; // Prevent multiple authentication attempts
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      print('AuthScreen: Starting biometric authentication...');
      final result = await BiometricService.authenticateWithBiometric();
      
      if (result) {
        print('AuthScreen: Biometric authentication successful');
        // Set authentication status and navigate to map
        AppLifecycleService().setAuthenticated(true);
        _navigateToMap();
      } else {
        print('AuthScreen: Biometric authentication failed');
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Biometric authentication failed. Please try again.';
          // If biometric fails and PIN is available, show PIN input
          if (_pinSet) {
            _showPinInput = true;
          }
        });
      }
    } catch (e) {
      print('AuthScreen: Error during biometric authentication: $e');
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Authentication error: $e';
        if (_pinSet) {
          _showPinInput = true;
        }
      });
    }
  }

  Future<void> _authenticateWithPin() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a 4-digit PIN';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      print('AuthScreen: Attempting PIN authentication...');
      final result = await BiometricService.authenticateWithPin(pin);
      
      if (result) {
        print('AuthScreen: PIN authentication successful');
        // Set authentication status and navigate to map
        AppLifecycleService().setAuthenticated(true);
        _navigateToMap();
      } else {
        print('AuthScreen: PIN authentication failed');
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'Incorrect PIN. Please try again.';
        });
        _pinController.clear();
      }
    } catch (e) {
      print('AuthScreen: Error during PIN authentication: $e');
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Authentication error: $e';
      });
    }
  }

  void _navigateToMap() {
    print('AuthScreen: Navigating to map screen');
    // Set authentication status to true
    AppLifecycleService().setAuthenticated(true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  void _skipAuthentication() {
    print('AuthScreen: Skipping authentication');
    // Set authentication status and navigate to map
    AppLifecycleService().setAuthenticated(true);
    _navigateToMap();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF111416),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If no security is enabled, show loading and navigate
    if (!_biometricEnabled && !_pinSet) {
      return Scaffold(
        backgroundColor: const Color(0xFF111416),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111416),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/logo.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Authentication Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Please authenticate to access the app',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Security method info
              if (_currentSecurityMethod != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentSecurityMethod!.contains('fingerprint')
                            ? Icons.fingerprint
                            : _currentSecurityMethod!.contains('face')
                                ? Icons.face
                                : Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security: ${_currentSecurityMethod!.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // PIN Input (if shown)
              if (_showPinInput) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Enter PIN Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          hintText: '0000',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _authenticateWithPin(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isAuthenticating ? null : _authenticateWithPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isAuthenticating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Authenticate'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Biometric authentication button
              if (_biometricEnabled && _biometricAvailable && !_showPinInput && _currentSecurityMethod != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticateWithBiometric,
                    icon: Icon(
                      _currentSecurityMethod!.contains('fingerprint')
                          ? Icons.fingerprint
                          : _currentSecurityMethod!.contains('face')
                              ? Icons.face
                              : Icons.lock,
                      size: 24,
                    ),
                    label: Text(
                      _isAuthenticating
                          ? 'Authenticating...'
                          : 'Use ${_currentSecurityMethod!.toUpperCase()}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Alternative authentication options
              if (_pinSet && _biometricEnabled) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showPinInput = !_showPinInput;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _showPinInput ? 'Use Biometric Instead' : 'Use PIN Instead',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Skip button (for development/testing)
              TextButton(
                onPressed: _skipAuthentication,
                child: const Text(
                  'Skip Authentication',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
} 