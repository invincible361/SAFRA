import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  bool _isLoading = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinSet = false;
  List<String> _availableBiometrics = [];
  String? _currentSecurityMethod;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('SecuritySetupScreen - Loading security status...');
      final biometricAvailable = await BiometricService.isBiometricAvailable();
      final biometricEnabled = await BiometricService.isBiometricEnabled();
      final pinSet = await BiometricService.isPinSet();
      final availableBiometrics = await BiometricService.getAvailableBiometricTypes();
      final currentMethod = await BiometricService.getCurrentSecurityMethod();

      print('SecuritySetupScreen - biometricAvailable: $biometricAvailable');
      print('SecuritySetupScreen - biometricEnabled: $biometricEnabled');
      print('SecuritySetupScreen - pinSet: $pinSet');
      print('SecuritySetupScreen - availableBiometrics: $availableBiometrics');
      print('SecuritySetupScreen - currentMethod: $currentMethod');

      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
        _pinSet = pinSet;
        _availableBiometrics = availableBiometrics;
        _currentSecurityMethod = currentMethod;
        _isLoading = false;
      });
    } catch (e) {
      print('SecuritySetupScreen - Error loading security status: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading security status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enableBiometric(BiometricType type) async {
    try {
      print('SecuritySetupScreen - Enabling biometric for type: $type');
      
      // First, try to authenticate to test if biometric is working
      final authResult = await BiometricService.testBiometricAuthentication();
      print('SecuritySetupScreen - Authentication result: $authResult');
      
      if (authResult) {
        // Authentication successful, enable biometric
        await BiometricService.enableBiometric(type);
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face Recognition enabled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Authentication failed, but let's still try to enable it
        // This might be the first time setup
        print('SecuritySetupScreen - Authentication failed, trying to enable anyway...');
        await BiometricService.enableBiometric(type);
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face Recognition enabled! Please test by signing out and back in.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('SecuritySetupScreen - Error enabling biometric: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling Face Recognition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disableBiometric() async {
    try {
      await BiometricService.disableBiometric();
      await _loadSecurityStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling biometric: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPinCode() async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set PIN Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: 'Enter 4-digit PIN',
                  hintText: '0000',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPinController,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  hintText: '0000',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final pin = pinController.text;
                final confirmPin = confirmPinController.text;
                
                if (pin.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN must be 4 digits'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (pin != confirmPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PINs do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop(true);
              },
              child: const Text('Set PIN'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await BiometricService.setPinCode(pinController.text);
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN code set successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error setting PIN: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removePinCode() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove PIN Code'),
          content: const Text('Are you sure you want to remove the PIN code?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await BiometricService.setPinCode('');
        await _loadSecurityStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN code removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing PIN: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Options',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Debug section
                  Card(
                    color: const Color(0xFF2A2A2A),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Debug Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Biometric Available: $_biometricAvailable'),
                          Text('Available Types: $_availableBiometrics'),
                          Text('Current Method: ${_currentSecurityMethod ?? "None"}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await BiometricService.testBiometricSetup();
                            },
                            child: const Text('Test Biometric Setup'),
                          ),
                          const SizedBox(height: 8),
                          // Direct Face Recognition button
                          if (_biometricAvailable && _availableBiometrics.contains('Face Recognition'))
                            ElevatedButton.icon(
                              onPressed: () => _enableBiometric(BiometricType.face),
                              icon: const Icon(Icons.face),
                              label: const Text('Enable Face Recognition Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Instructions Card
                  Card(
                    color: const Color(0xFF1E3A8A),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'How to Enable Face Unlock',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '1. Make sure Face ID is set up on your device\n'
                            '2. Tap "Enable Face Recognition Now" below\n'
                            '3. Look at your device when prompted\n'
                            '4. After setup, sign out and sign back in to test',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Security Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Security Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _currentSecurityMethod != null
                                    ? Icons.security
                                    : Icons.security_outlined,
                                color: _currentSecurityMethod != null
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentSecurityMethod != null
                                    ? 'Security Enabled (${_currentSecurityMethod})'
                                    : 'No Security Method Set',
                                style: TextStyle(
                                  color: _currentSecurityMethod != null
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Biometric Authentication Section
                  if (_biometricAvailable) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Biometric Authentication',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Available: ${_availableBiometrics.join(', ')}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            if (_biometricEnabled)
                              ElevatedButton.icon(
                                onPressed: _disableBiometric,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Disable Biometric'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              )
                            else
                              ...(_availableBiometrics.map((biometric) {
                                BiometricType type;
                                switch (biometric) {
                                  case 'Fingerprint':
                                    type = BiometricType.fingerprint;
                                    break;
                                  case 'Face Recognition':
                                    type = BiometricType.face;
                                    break;
                                  case 'Iris':
                                    type = BiometricType.iris;
                                    break;
                                  default:
                                    type = BiometricType.fingerprint;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _enableBiometric(type),
                                    icon: Icon(
                                      biometric == 'Fingerprint'
                                          ? Icons.fingerprint
                                          : biometric == 'Face Recognition'
                                              ? Icons.face
                                              : Icons.visibility,
                                    ),
                                    label: Text('Enable $biometric'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                );
                              })),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // PIN Code Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PIN Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pinSet ? 'PIN is set' : 'No PIN set',
                            style: TextStyle(
                              color: _pinSet ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_pinSet)
                            ElevatedButton.icon(
                              onPressed: _removePinCode,
                              icon: const Icon(Icons.lock_open),
                              label: const Text('Remove PIN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _setPinCode,
                              icon: const Icon(Icons.lock),
                              label: const Text('Set PIN Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Information Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Security Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Biometric authentication uses your device\'s built-in security features\n'
                            '• PIN code provides an alternative authentication method\n'
                            '• You can use both biometric and PIN for maximum security\n'
                            '• Security is required each time you open the app',
                            style: TextStyle(color: Colors.grey),
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
} 