import 'package:flutter/material.dart';
import 'package:safra_app/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:provider/provider.dart' as provider;
import '../widgets/language_selector.dart';
import '../services/enhanced_language_service.dart';
import '../services/biometric_service.dart';
import '../config/oauth_config.dart';
import '../config/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinSet = false;
  String? _currentSecurityMethod;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
    
    // Add periodic auth state check for OAuth completion
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          print('LoginScreen: OAuth completed, user authenticated');
          timer.cancel();
          // The main.dart auth listener should handle navigation
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final biometricAvailable = await BiometricService.isBiometricAvailable();
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      final pinSet = await BiometricService.isPinSet();
      final currentMethod = await BiometricService.getCurrentSecurityMethod();

      if (mounted) {
        setState(() {
          _biometricAvailable = biometricAvailable;
          _biometricEnabled = biometricEnabled;
          _pinSet = pinSet;
          _currentSecurityMethod = currentMethod;
        });
      }
    } catch (e) {
      print('Error checking biometric status: $e');
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await BiometricService.authenticateWithBiometric();
      if (success) {
        // Biometric authentication successful, try to get stored credentials
        // For now, we'll just show a success message and let user use regular login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication successful! Please use your credentials to login.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Biometric authentication failed. Please use your credentials.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _authenticateWithPin() async {
    final pin = await BiometricService.getPinCode();
    if (pin != null) {
      // Show PIN input dialog
      _showPinInputDialog();
    }
  }

  void _showPinInputDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final enteredPin = pinController.text;
              if (enteredPin.isNotEmpty) {
                final success = await BiometricService.authenticateWithPin(enteredPin);
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIN authentication successful! Please use your credentials to login.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    setState(() {
                      _errorMessage = 'Incorrect PIN. Please use your credentials.';
                    });
                  }
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid credentials';
        });
      } else {
        // Login successful - auth state listener will handle navigation
        print('Login successful - user: ${response.user?.email}');
        print('Auth state change should be triggered');
        // Don't reset loading state here, let the auth listener handle it
        return;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    } finally {
      // Only reset loading if login failed or had error
      if (mounted && _errorMessage != null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithProvider(Provider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print('Attempting to sign in with provider: $provider');
      print('Current auth state before OAuth: ${Supabase.instance.client.auth.currentSession != null ? "User is signed in" : "No user signed in"}');

      // Try to get the current session first
      final currentSession = Supabase.instance.client.auth.currentSession;
      print('Current session before OAuth: ${currentSession != null ? "exists" : "null"}');

      // For mobile, explicitly set the redirect URL to ensure proper deep linking
      final redirectUrl = kIsWeb 
          ? OAuthConfig.getRedirectUrl(true) 
          : OAuthConfig.mobileRedirectUrl;

      print('Using redirect URL: $redirectUrl');

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: redirectUrl,
        scopes: 'email profile',
      );

      print('OAuth sign-in initiated successfully for $provider');
      print('OAuth response: $response');

      // For mobile, wait a bit and then check if we have a session
      if (!kIsWeb) {
        // Wait for the OAuth flow to potentially complete
        await Future.delayed(const Duration(seconds: 3));
        
        // Try to refresh the session to see if OAuth completed
        try {
          await Supabase.instance.client.auth.refreshSession();
          print('Session refresh attempted');
        } catch (e) {
          print('Session refresh error: $e');
        }
        
        // Check if we now have a session
        final newSession = Supabase.instance.client.auth.currentSession;
        print('Session after OAuth delay and refresh: ${newSession != null ? "exists" : "null"}');
        
        if (newSession != null) {
          print('OAuth completed successfully, user authenticated');
          // The main.dart auth listener should handle navigation
        } else {
          // Show message to complete in browser
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please complete the sign-in in your browser and return to the app'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      }

    } catch (e) {
      print('Error signing in with $provider: $e');
      setState(() {
        _errorMessage = 'Failed to sign in with ${provider.name}: $e';
      });
    } finally {
      // Reset loading state; navigation will be handled by the auth state listener
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LanguageSelector(),
                const SizedBox(height: 40),
                Center(
                  child: Image.asset('assets/logo.png', height: 100),
                ),
                const SizedBox(height: 30),
                provider.Consumer<EnhancedLanguageService>(
                  builder: (context, languageService, child) {
                    final welcomeText = languageService.getStaticTranslation('welcome');
                    final getStartedText = languageService.getStaticTranslation('getStarted');
                    
                    return Column(
                      children: [
                        Text(
                          welcomeText,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getStartedText,
                          style: TextStyle(
                              fontSize: 16, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Email
                _buildGlassField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email,
                ),
                const SizedBox(height: 20),

                // Password
                _buildGlassField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 12),

                provider.Consumer<EnhancedLanguageService>(
                  builder: (context, languageService, child) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _sendPasswordResetEmail,
                        child: Text(
                          languageService.getStaticTranslation('forgotPassword'),
                          style: TextStyle(color: AppColors.secondaryAccent),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                provider.Consumer<EnhancedLanguageService>(
                  builder: (context, languageService, child) {
                    return _buildGradientButton(languageService.getStaticTranslation('login'), _login);
                  },
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 30),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    provider.Consumer<EnhancedLanguageService>(
                      builder: (context, languageService, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(languageService.getStaticTranslation('or'),
                              style: TextStyle(color: Colors.grey[400])),
                        );
                      },
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 30),

                // OAuth Button
                _buildOAuthButton(),

                const SizedBox(height: 30),

                // Signup Link
                provider.Consumer<EnhancedLanguageService>(
                  builder: (context, languageService, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(languageService.getStaticTranslation('dontHaveAccount'),
                            style: const TextStyle(color: AppColors.textSecondary)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen()),
                            );
                          },
                          child: Text(languageService.getStaticTranslation('signUp'),
                              style: TextStyle(color: AppColors.secondaryAccent)),
                        )
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
                 style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
                     labelStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            text,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _signInWithProvider(Provider.google),
      icon: Image.asset('assets/logo.png', height: 20), // Using existing logo instead of missing google.jpeg
      label: const Text("Sign in with Google"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}