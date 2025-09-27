import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _pinCodeKey = 'pin_code';
  static const String _biometricTypeKey = 'biometric_type';

  // Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      print('BiometricService - canCheckBiometrics: $isAvailable');
      print('BiometricService - isDeviceSupported: $isDeviceSupported');
      
      final result = isAvailable && isDeviceSupported;
      print('BiometricService - isBiometricAvailable: $result');
      
      return result;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      print('BiometricService - Error in isBiometricAvailable: $e');
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  // Check if biometric authentication is enabled by user
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  // Enable biometric authentication
  static Future<void> enableBiometric(BiometricType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
    await prefs.setString(_biometricTypeKey, type.toString());
  }

  // Disable biometric authentication
  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_biometricTypeKey);
  }

  // Set PIN code
  static Future<void> setPinCode(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinCodeKey, pin);
  }

  // Get PIN code
  static Future<String?> getPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinCodeKey);
  }

  // Check if PIN is set
  static Future<bool> isPinSet() async {
    final pin = await getPinCode();
    return pin != null && pin.isNotEmpty;
  }

  // Test biometric authentication (for setup)
  static Future<bool> testBiometricAuthentication() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print('BiometricService - No available biometrics');
        return false;
      }

      print('BiometricService - Testing biometric authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric security',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      print('BiometricService - Authentication test result: $result');
      return result;
    } catch (e) {
      print('BiometricService - Error during biometric test: $e');
      return false;
    }
  }

  // Authenticate with biometric - generic biometric authentication
  static Future<bool> authenticateWithBiometric() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return false;

      // Use generic authentication message
      String authReason = 'Please authenticate to access the app';

      final result = await _localAuth.authenticate(
        localizedReason: authReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true, // This indicates it's a security-critical operation
        ),
      );

      return result;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  // Authenticate with PIN
  static Future<bool> authenticateWithPin(String enteredPin) async {
    try {
      final storedPin = await getPinCode();
      return storedPin == enteredPin;
    } catch (e) {
      debugPrint('Error during PIN authentication: $e');
      return false;
    }
  }

  // Get biometric type string
  static String getBiometricTypeString(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris';
      default:
        return 'Biometric';
    }
  }

  // Get all available biometric types as strings
  static Future<List<String>> getAvailableBiometricTypes() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.map((type) => getBiometricTypeString(type)).toList();
  }

  // Check if any security method is enabled
  static Future<bool> isSecurityEnabled() async {
    try {
      final biometricEnabled = await isBiometricEnabled();
      final pinSet = await isPinSet();
      
      print('BiometricService - isBiometricEnabled: $biometricEnabled');
      print('BiometricService - isPinSet: $pinSet');
      
      final result = biometricEnabled || pinSet;
      print('BiometricService - isSecurityEnabled: $result');
      
      return result;
    } catch (e) {
      print('BiometricService - Error in isSecurityEnabled: $e');
      return false;
    }
  }

  // Get current security method
  static Future<String?> getCurrentSecurityMethod() async {
    final biometricEnabled = await isBiometricEnabled();
    final pinSet = await isPinSet();
    
    if (biometricEnabled) {
      final prefs = await SharedPreferences.getInstance();
      final typeString = prefs.getString(_biometricTypeKey);
      if (typeString != null) {
        return typeString.replaceAll('BiometricType.', '');
      }
    }
    
    if (pinSet) {
      return 'PIN';
    }
    
    return null;
  }

  // Test method to debug biometric issues
  static Future<void> testBiometricSetup() async {
    print('=== BiometricService Test ===');
    
    try {
      final isAvailable = await isBiometricAvailable();
      print('1. Biometric available: $isAvailable');
      
      final availableTypes = await getAvailableBiometrics();
      print('2. Available biometric types: $availableTypes');
      
      final isEnabled = await isBiometricEnabled();
      print('3. Biometric enabled: $isEnabled');
      
      final pinSet = await isPinSet();
      print('4. PIN set: $pinSet');
      
      final securityEnabled = await isSecurityEnabled();
      print('5. Security enabled: $securityEnabled');
      
      final currentMethod = await getCurrentSecurityMethod();
      print('6. Current security method: $currentMethod');
      
      print('=== End BiometricService Test ===');
    } catch (e) {
      print('Error in testBiometricSetup: $e');
    }
  }
}