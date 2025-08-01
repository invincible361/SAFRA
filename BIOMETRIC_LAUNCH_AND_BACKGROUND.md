# Biometric Authentication - Launch and Background

## Updated Behavior

### Biometric Check Timing

**App Launch**: Biometric check when user has an active session
**App Resume**: Biometric check when app is resumed from background (suspended state)

## App Lifecycle Flow

### 1. App Launch (Fresh Start)
```
App Launch → Check Session → 
├─ If Session Exists → Set Authenticated State → Check Biometric → 
│  ├─ If Biometric Enabled → Show AuthScreen
│  └─ If Biometric Disabled → Go to MapScreen
└─ If No Session → Go to LoginScreen (No Biometric Check)
```

### 2. App Background/Foreground Cycle
```
App Running → User puts app in background → App Suspended
App Suspended → User brings app to foreground → App Resumed
App Resumed → Check if was suspended AND user authenticated → 
├─ If Yes → Show Biometric Auth
└─ If No → Continue normally
```

## Implementation Details

### Authentication State Management

**AppLifecycleService State Tracking**:
```dart
bool _wasSuspended = false;  // Tracks if app was suspended
bool _isInBackground = false; // Tracks if app is in background
bool _isAuthenticated = false; // Tracks if user is authenticated
```

**State Changes**:
- **User Signs In**: `_isAuthenticated = true`
- **User Signs Out**: `_isAuthenticated = false`
- **App Suspended**: `_wasSuspended = true`, `_isInBackground = true`
- **App Resumed**: Check biometric if `_wasSuspended && _isAuthenticated`
- **App Detached**: Reset all states to false

### Main.dart Updates

**App Launch Logic**:
```dart
if (session != null) {
  // User has session, set authenticated state and check biometric
  AppLifecycleService().setAuthenticated(true);
  await _checkBiometricAndNavigate();
} else {
  // No session, go directly to login
  _currentScreen = const LoginScreen();
}
```

**Auth State Change Listener**:
```dart
if (event == AuthChangeEvent.signedIn && session != null) {
  // Set authenticated state and navigate to map
  AppLifecycleService().setAuthenticated(true);
  _currentScreen = const MapScreen();
} else if (event == AuthChangeEvent.signedOut) {
  // Clear authenticated state and navigate to login
  AppLifecycleService().setAuthenticated(false);
  _currentScreen = const LoginScreen();
}
```

## Key Features

### ✅ **Launch Biometric Check**
- Biometric check when app launches with active session
- Proper authentication state tracking
- Biometric verification before accessing app

### ✅ **Background Biometric Check**
- Biometric check when app is resumed from background
- Only checks if app was suspended and user was authenticated
- Maintains security when returning from background

### ✅ **Proper State Management**
- Tracks user authentication state
- Tracks app suspension state
- Only shows biometric when appropriate

### ✅ **Better User Experience**
- Security at both launch and resume
- Proper session handling
- Clear authentication flow

## Testing Scenarios

### 1. Fresh App Launch (With Session)
1. Login to app and close completely
2. Launch app fresh
3. **Expected**: Biometric check appears (if enabled)

### 2. Fresh App Launch (No Session)
1. Don't login to app
2. Launch app fresh
3. **Expected**: No biometric check, go to login

### 3. Background to Foreground (Authenticated User)
1. Login to app
2. Put app in background (home button or switch apps)
3. Bring app back to foreground
4. **Expected**: Biometric check appears

### 4. Background to Foreground (Not Authenticated)
1. Don't login to app
2. Put app in background
3. Bring app back to foreground
4. **Expected**: No biometric check, continue normally

### 5. App Inactive (Not Suspended)
1. Open app
2. Pull down notification center (app becomes inactive but not suspended)
3. Close notification center
4. **Expected**: No biometric check

## Debug Logs

### App Launch with Session
```
Current session on app start: exists
User already signed in, setting authenticated state and checking biometric security...
Checking biometric security...
Security enabled: true
Security enabled, showing AuthScreen for biometric verification
```

### App Launch without Session
```
Current session on app start: null
No session found, going directly to login screen
```

### App Suspended
```
AppLifecycleService: App suspended (going to background)
```

### App Resumed (Authenticated)
```
AppLifecycleService: App resumed from background
AppLifecycleService: Was in background: true
AppLifecycleService: Was suspended: true
AppLifecycleService: Was authenticated: true
AppLifecycleService: App was suspended and user was authenticated, checking biometric...
```

### User Sign In
```
User signed in, setting authenticated state and navigating to map screen
AppLifecycleService: Authentication status set to: true
```

### User Sign Out
```
User signed out, clearing authenticated state and navigating to login screen
AppLifecycleService: Authentication status set to: false
```

## Configuration

### Biometric Settings
- **Enable Biometric**: Required for both launch and background biometric check
- **Disable Biometric**: No biometric check at all
- **PIN Fallback**: Available if biometric fails

### App Settings
- **Background App Refresh**: Should be enabled for proper lifecycle tracking
- **Location Services**: Required for map functionality
- **Biometric Permissions**: Required for biometric authentication

## Files Modified

1. **`lib/main.dart`**
   - Added biometric check on app launch when user has session
   - Added authentication state management
   - Updated auth state change listener
   - Enhanced logging for debugging

2. **`lib/services/app_lifecycle_service.dart`**
   - Maintains existing background biometric check functionality
   - Proper state tracking for both launch and background scenarios

## Benefits

### Security
- ✅ **Launch Security**: Biometric check when app starts with session
- ✅ **Background Security**: Biometric check when returning from background
- ✅ **Session Awareness**: Only checks when user is authenticated
- ✅ **State Validation**: Proper state tracking and validation

### User Experience
- ✅ **Consistent Security**: Biometric check at appropriate times
- ✅ **Fast Navigation**: Direct to login when no session
- ✅ **Proper Flow**: Clear authentication and navigation flow

### Performance
- ✅ **Efficient Checks**: Biometric only when needed
- ✅ **State Management**: Proper tracking of app and user states
- ✅ **Error Handling**: Graceful handling of biometric failures

The updated behavior ensures that biometric authentication is checked both at app launch (when user has a session) and when the app is resumed from a suspended background state, providing comprehensive security while maintaining a good user experience. 