import 'dart:math';
import 'package:flutter/material.dart';

class SetPasswordScreen extends StatefulWidget {
  final String fullName;

  const SetPasswordScreen({super.key, required this.fullName});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void _generatePassword() {
    const length = 12;
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#\$%^&*()';
    final rand = Random();

    String password = List.generate(length, (_) {
      return chars[rand.nextInt(chars.length)];
    }).join();

    setState(() {
      newPasswordController.text = password;
      confirmPasswordController.text = password;
    });
  }

  bool _validateMatch() {
    return newPasswordController.text == confirmPasswordController.text;
  }

  bool _isFormValid() {
    return _formKey.currentState?.validate() == true &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        _validateMatch();
  }

  String getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(widget.fullName);

    return Scaffold(
      backgroundColor: const Color(0xFF111416),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Set Password'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFCAE3F2),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a strong password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your password should be at least 8 characters long and include a mix of letters, numbers, and symbols.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: _inputDecoration('New Password'),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: _inputDecoration('Confirm Password'),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (!_validateMatch()) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Set Password button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFormValid()
                            ? () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title:
                              const Text('Password Set Successfully'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('Username: ${widget.fullName}'),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Password: ${newPasswordController.text}'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid()
                              ? const Color(0xFFCAE3F2)
                              : const Color(0xFF2A2E32),
                          foregroundColor: _isFormValid()
                              ? Colors.black
                              : Colors.white54,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Set Password'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Generate Password button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _generatePassword,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFCAE3F2),
                          side: const BorderSide(color: Color(0xFFCAE3F2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Generate Password'),
                      ),
                    ),
                  ],
                ),
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
}
