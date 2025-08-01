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
    
    // Biometric check disabled - only happens at app startup
    print('AppLifecycleService: Skipping biometric check on resume (only at startup)');
    
    // Reset background state
    _isInBackground = false;
    _wasSuspended = false;
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