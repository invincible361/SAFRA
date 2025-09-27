import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigation service for showing dialogs from anywhere
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get context => navigatorKey.currentContext;
}

class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _isAuthenticated = false;
  bool _isInBackground = false;
  bool _wasSuspended = false;

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
    
    // Reset background state
    _isInBackground = false;
    _wasSuspended = false;
  }
}

// Lifecycle event handler
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback? resumedCallBack;
  final AsyncCallback? suspendingCallBack;
  final AsyncCallback? detachedCallBack;

  LifecycleEventHandler({
    this.resumedCallBack,
    this.suspendingCallBack,
    this.detachedCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (resumedCallBack != null) {
          await resumedCallBack!();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
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
        // Handle hidden state if needed
        break;
    }
  }
}

typedef AsyncCallback = Future<void> Function();