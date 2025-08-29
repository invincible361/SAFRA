import 'package:flutter/material.dart';
import 'package:safra_app/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selector.dart';
import '../widgets/translated_text.dart';
import '../services/enhanced_language_service.dart';
import '../config/oauth_config.dart';

class AppColors {
  static const Color backgroundTop = Color(0xFF242C3B);
  static const Color backgroundBottom = Color(0xFF2B3D80);
  static const Color surface = Color(0xFF1E2A47);

  static const Color primaryAccent = Color(0xFF6C63FF); // neon purple
  static const Color secondaryAccent = Color(0xFF00D4FF); // neon cyan

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8D1);
}

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
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
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
      
      // Use the centralized OAuth configuration for all platforms
      final redirectUrl = OAuthConfig.getRedirectUrl(kIsWeb);
      
      print('Using redirect URL: ${kIsWeb ? redirectUrl : "(mobile: default deep link)"}');
      print('Provider: $provider');
      
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        // Explicitly pass redirect for all platforms so Supabase returns to our app
        redirectTo: redirectUrl,
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
        decoration: const BoxDecoration(
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
                TranslatedText(
                  text: 'Welcome Back',
                  staticKey: 'welcome',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TranslatedText(
                  text: "Let's Get Started",
                  staticKey: 'getStarted',
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
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

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _sendPasswordResetEmail,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: AppColors.secondaryAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                _buildGradientButton("Login", _login),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR",
                          style: TextStyle(color: Colors.grey[400])),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 30),

                // OAuth Button
                _buildOAuthButton(),

                const SizedBox(height: 30),

                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?",
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: const Text("Sign Up",
                          style: TextStyle(color: AppColors.secondaryAccent)),
                    )
                  ],
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
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
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
          gradient: const LinearGradient(
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
