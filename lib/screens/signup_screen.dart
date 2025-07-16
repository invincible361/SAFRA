import 'package:flutter/material.dart';
import 'package:safra_app/screens/otpverity_screen.dart';

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

  final List<String> govIdTypes = [
    'PAN Card',
    'Aadhar Card',
    'Driving License',
    'Passport'
  ];

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const Text(
          'Here you can place the actual terms and conditions of SAFRA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isFormComplete() {
    return _formKey.currentState?.validate() == true &&
        fullNameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        selectedGovId != null &&
        idNumberController.text.isNotEmpty &&
        termsAccepted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111416),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logo.png',
                height: 275,
                width: 275,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            const Center(
              child: Text(
                'Create an Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                children: [
                  _buildInputField('Full Name', controller: fullNameController),
                  const SizedBox(height: 16),
                  _buildInputField('Email',
                      inputType: TextInputType.emailAddress,
                      controller: emailController),
                  const SizedBox(height: 16),
                  _buildInputField('Phone Number',
                      inputType: TextInputType.phone,
                      controller: phoneController),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: _dropdownDecoration('Select Government ID'),
                    value: selectedGovId,
                    dropdownColor: const Color(0xFF2A2E32),
                    style: const TextStyle(color: Colors.white),
                    items: govIdTypes
                        .map((id) =>
                        DropdownMenuItem(value: id, child: Text(id)))
                        .toList(),
                    onChanged: (value) => setState(() {
                      selectedGovId = value;
                    }),
                    validator: (value) =>
                    value == null ? 'Please select a Government ID' : null,
                  ),
                  const SizedBox(height: 16),

                  if (selectedGovId != null)
                    TextFormField(
                      controller: idNumberController,
                      decoration: _inputDecoration('ID Number'),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                    ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: termsAccepted,
                        onChanged: (val) => setState(() {
                          termsAccepted = val ?? false;
                        }),
                      ),
                      GestureDetector(
                        onTap: _showTermsDialog,
                        child: const Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormComplete()
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtpScreen(
                              fullName: fullNameController.text,
                            ),
                          ),
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormComplete()
                            ? const Color(0xFFCAE3F2)
                            : const Color(0xFF2A2E32),
                        foregroundColor: _isFormComplete()
                            ? Colors.black
                            : Colors.white54,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: const Color(0xFF2A2E32),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.white54),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF2A2E32),
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildInputField(
      String label, {
        TextInputType inputType = TextInputType.text,
        TextEditingController? controller,
      }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      validator: (value) =>
      value == null || value.isEmpty ? 'This field is required' : null,
    );
  }
}
