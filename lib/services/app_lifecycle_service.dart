import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'biometric_service.dart';
import '../screens/auth_screen.dart';
import '../main.dart'; // Import to access navigatorKey

class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _isAuthenticated = false;
  bool _isInBackground = false;
  bool _wasSuspended = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Initialize the service
  void initialize(BuildContext context) {
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        detachedCallBack: () async => _onAppDetached(),
        resumedCallBack: () async => _onAppResumed(),
        suspendingCallBack: () async => _onAppSuspended(),
      ),
    );
  }

  // Set authentication status
  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    print('AppLifecycleService: Authentication status set to: $authenticated');
  }

  // App detached (completely closed)
  Future<void> _onAppDetached() async {
    print('AppLifecycleService: App detached');
    _isInBackground = false;
    _wasSuspended = false;
    _isAuthenticated = false;
  }

  // App suspended (background)
  Future<void> _onAppSuspended() async {
    print('AppLifecycleService: App suspended (going to background)');
    _isInBackground = true;
    _wasSuspended = true;
  }

  // App resumed (foreground)
  Future<void> _onAppResumed() async {
    print('AppLifecycleService: App resumed from background');
    print('AppLifecycleService: Was in background: $_isInBackground');
    print('AppLifecycleService: Was suspended: $_wasSuspended');
    print('AppLifecycleService: Was authenticated: $_isAuthenticated');
    
    // Always trigger biometric authentication when app is resumed from background
    if (_wasSuspended && _isAuthenticated) {
      print('AppLifecycleService: App resumed from background while authenticated, triggering biometric check');
      await _triggerBiometricAuthentication();
    }
    
    // Reset background state
    _isInBackground = false;
    _wasSuspended = false;
  }

  // Trigger biometric authentication
  Future<void> _triggerBiometricAuthentication() async {
    try {
      print('AppLifecycleService: Starting automatic biometric authentication...');
      
      // Check if biometric security is enabled
      final isSecurityEnabled = await BiometricService.isSecurityEnabled();
      print('AppLifecycleService: Security enabled: $isSecurityEnabled');
      
      if (isSecurityEnabled) {
        // Check if biometrics are available and enabled
        final biometricAvailable = await BiometricService.isBiometricAvailable();
        final biometricEnabled = await BiometricService.isBiometricEnabled();
        final pinSet = await BiometricService.isPinSet();
        
        print('AppLifecycleService: Biometric available: $biometricAvailable, enabled: $biometricEnabled, PIN set: $pinSet');
        
        if (biometricEnabled) {
          // Try biometric authentication
          print('AppLifecycleService: Attempting biometric authentication...');
          final success = await BiometricService.authenticateWithBiometric();
          
          if (success) {
            print('AppLifecycleService: Biometric authentication successful');
            // User can continue using the app
          } else {
            print('AppLifecycleService: Biometric authentication failed, redirecting to login');
            _redirectToLogin();
          }
        } else if (pinSet) {
          // Show PIN authentication dialog
          print('AppLifecycleService: PIN authentication required');
          _showPinAuthenticationDialog();
        } else {
          print('AppLifecycleService: No security method available, allowing access');
        }
      } else {
        print('AppLifecycleService: No security enabled, allowing access');
      }
    } catch (e) {
      print('AppLifecycleService: Error during biometric authentication: $e');
      // On error, redirect to login for security
      _redirectToLogin();
    }
  }

  // Show PIN authentication dialog
  void _showPinAuthenticationDialog() {
    // This will be handled by the main app to show a PIN dialog
    print('AppLifecycleService: PIN authentication required - should show dialog');
    // We'll implement this in the main app
  }

  // Redirect to login screen
  void _redirectToLogin() {
    print('AppLifecycleService: Redirecting to login screen');
    // This will be handled by the main app to navigate to login
  }

  // Check if app is in background
  bool get isInBackground => _isInBackground;
  
  // Check if user is authenticated
  bool get isAuthenticated => _isAuthenticated;
  
  // Check if app was suspended
  bool get wasSuspended => _wasSuspended;
}

// Lifecycle event handler
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? detachedCallBack;
  final Future<void> Function()? resumedCallBack;
  final Future<void> Function()? suspendingCallBack;

  LifecycleEventHandler({
    this.detachedCallBack,
    this.resumedCallBack,
    this.suspendingCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumedCallBack != null) {
          await resumedCallBack!();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        if (suspendingCallBack != null) {
          await suspendingCallBack!();
        }
        break;
      case AppLifecycleState.detached:
        if (detachedCallBack != null) {
          await detachedCallBack!();
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
} 