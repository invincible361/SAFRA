import 'package:flutter/material.dart';
import 'package:safra_app/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safra_app/screens/map_screen.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selector.dart';
import '../widgets/translated_text.dart';
import '../services/enhanced_language_service.dart';
import '../config/oauth_config.dart';

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

  @override
  void initState() {
    super.initState();
    // Auth state changes are handled in AuthWrapper
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
        _errorMessage = 'Please fill in all fields'; // This will be translated
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
          _errorMessage = 'Invalid credentials'; // This will be translated
        });
      }
      // Navigation is handled by AuthWrapper
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      
      // Use the centralized OAuth configuration for web only
      final redirectUrl = OAuthConfig.getRedirectUrl(kIsWeb);
      
      print('Using redirect URL: ${kIsWeb ? redirectUrl : "(mobile: default deep link)"}');
      print('Provider: $provider');
      
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        // For web, explicitly pass redirect; for mobile, rely on platform deep link
        redirectTo: kIsWeb ? redirectUrl : null,
        // Request basic scopes to ensure email/profile are returned
        scopes: 'email profile',
      );
      print('OAuth sign-in initiated successfully for $provider');
      print('OAuth response: $response');
      
      // Check if we have a session immediately after OAuth call
      final sessionAfterOAuth = Supabase.instance.client.auth.currentSession;
      print('Session after OAuth call: ${sessionAfterOAuth != null ? "exists" : "null"}');
      if (sessionAfterOAuth != null) {
        print('Session user: ${sessionAfterOAuth.user?.email}');
      }
      
      // Don't wait for completion here - let the auth state listener handle it
      // The user will be redirected back to the app after sign-in
      
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
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText(text: 'Password reset link sent to your email'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          text: 'SAFRA App',
          useStaticTranslation: true,
          staticKey: 'appTitle',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          LanguageSelector(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and Welcome Text
              Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 24),
                  TranslatedText(
                    text: 'Welcome Back',
                    useStaticTranslation: true,
                    staticKey: 'welcome',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TranslatedText(
                    text: 'Let\'s Get Started',
                    useStaticTranslation: true,
                    staticKey: 'getStarted',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 8),
              
              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendPasswordResetEmail,
                  child: TranslatedText(text: 'Forgot Password?'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCAE3F2),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TranslatedText(
                        text: 'Login',
                        useStaticTranslation: true,
                        staticKey: 'login',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: TranslatedText(
                    text: _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              
              // OAuth Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _signInWithProvider(Provider.google),
                      icon: Image.asset('assets/logo.png', height: 20), // Replace with Google logo asset
                      label: TranslatedText(
                        text: 'Sign in with Google',
                        useStaticTranslation: true,
                        staticKey: 'signInWithGoogle',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TranslatedText(
                    text: 'Don\'t have an account?',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: TranslatedText(text: 'Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
