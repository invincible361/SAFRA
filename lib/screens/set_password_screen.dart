import 'dart:math';
import 'package:flutter/material.dart';
import 'package:safra_app/screens/main_screen.dart';

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
  bool _obscureNew = true;
  bool _obscureConfirm = true;

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

            // Main Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1F22), Color(0xFF222629)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a strong password 🔐',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'At least 8 characters with letters, numbers & symbols.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // New Password
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: _obscureNew,
                      decoration: _inputDecoration('New Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() => _obscureNew = !_obscureNew);
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (val.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: _inputDecoration('Confirm Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (!_validateMatch()) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Set Password button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFormValid()
                            ? () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1C1F22),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16)),
                              title: const Text(
                                '✅ Password Set Successfully',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Username: ${widget.fullName}',
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Password: ${newPasswordController.text}',
                                    style: const TextStyle(
                                        color: Colors.white70),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text(
                                    'OK',
                                    style:
                                    TextStyle(color: Colors.blueAccent),
                                  ),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        child: const Text(
                          'Set Password',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Generate Password button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generatePassword,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFCAE3F2),
                          side: const BorderSide(color: Color(0xFFCAE3F2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.autorenew),
                        label: const Text('Generate Strong Password'),
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.white54),
    );
  }
}
