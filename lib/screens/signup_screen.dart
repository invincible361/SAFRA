import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otpverity_screen.dart';

class AppColors {
  static const Color backgroundTop = Color(0xFF242C3B);
  static const Color backgroundBottom = Color(0xFF2B3D80);
  static const Color surface = Color(0xFF1E2A47);

  static const Color primaryAccent = Color(0xFF6C63FF); // neon purple
  static const Color secondaryAccent = Color(0xFF00D4FF); // neon cyan

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8D1);
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final idNumberController = TextEditingController();
  String? selectedGovId;
  bool termsAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> govIdTypes = [
    'PAN Card', 'Aadhar Card', 'Driving License', 'Passport'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(child: Image.asset('assets/logo.png', height: 100)),
                const SizedBox(height: 40),
                Text(
                  'Create Your Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Establishing a circle of trust and safety.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildGlassField('Full Name', controller: fullNameController),
                      const SizedBox(height: 20),
                      _buildGlassField('Email',
                          controller: emailController,
                          inputType: TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      _buildGlassField('Phone Number',
                          controller: phoneController,
                          inputType: TextInputType.phone),
                      const SizedBox(height: 20),
                      _buildDropdownField(),
                      const SizedBox(height: 20),
                      if (selectedGovId != null)
                        _buildGlassField('ID Number',
                            controller: idNumberController),
                      const SizedBox(height: 20),
                      _buildTermsAndConditions(),
                      const SizedBox(height: 30),
                      _buildGradientButton(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                              color: Colors.red.shade300, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassField(String label,
      {required TextEditingController controller, TextInputType? inputType}) {
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
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: GoogleFonts.lato(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        validator: (value) =>
        (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedGovId,
        dropdownColor: AppColors.surface,
        items: govIdTypes
            .map((id) => DropdownMenuItem(
          value: id,
          child: Text(id,
              style: GoogleFonts.lato(color: AppColors.textPrimary)),
        ))
            .toList(),
        onChanged: (value) => setState(() => selectedGovId = value),
        decoration: InputDecoration(
          labelText: 'Select Government ID',
          labelStyle: GoogleFonts.lato(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        validator: (value) => value == null ? 'Required' : null,
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(
          value: termsAccepted,
          onChanged: (val) => setState(() => termsAccepted = val ?? false),
          activeColor: AppColors.primaryAccent,
          checkColor: AppColors.backgroundBottom,
        ),
        Flexible(
          child: Text(
            'I agree to the Terms & Conditions',
            style: GoogleFonts.lato(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: !_isLoading ? _handleSignUp : null,
      child: Container(
        width: double.infinity,
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
            "Register",
            style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate() || !termsAccepted) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: '${phoneController.text.trim()}A@123',
      );
      if (mounted && response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => OtpScreen(fullName: fullNameController.text)),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
