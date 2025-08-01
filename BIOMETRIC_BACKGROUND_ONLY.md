# Biometric Authentication - Background Only

## Updated Behavior

### Biometric Check Timing

**Before**: Biometric was checked on every app launch
**After**: Biometric is only checked when app is resumed from background (suspended state)

## App Lifecycle Flow

### 1. App Launch (Fresh Start)
```
App Launch → Check Session → 
├─ If Session Exists → Go to MapScreen
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

### AppLifecycleService Updates

**New State Tracking**:
```dart
bool _wasSuspended = false;  // Tracks if app was suspended
bool _isInBackground = false; // Tracks if app is in background
bool _isAuthenticated = false; // Tracks if user is authenticated
```

**State Changes**:
- **App Suspended**: `_wasSuspended = true`, `_isInBackground = true`
- **App Resumed**: Check biometric only if `_wasSuspended && _isAuthenticated`
- **App Detached**: Reset all states to false

### Main.dart Updates

**App Launch Logic**:
```dart
// Before
if (session != null) {
  await _checkBiometricAndNavigate(); // Biometric check on launch
} else {
  await _checkBiometricAndNavigate(); // Biometric check on launch
}

// After
if (session != null) {
  // Go directly to map (no biometric check)
  _currentScreen = const MapScreen();
} else {
  // Go directly to login (no biometric check)
  _currentScreen = const LoginScreen();
}
```

**App Resume Logic**:
```dart
// Simplified - AppLifecycleService handles biometric check
Future<void> _handleAppResumed() async {
  print('Main: App resumed, letting AppLifecycleService handle biometric check');
  // AppLifecycleService will handle biometric check if needed
}
```

## Key Features

### ✅ **Correct Timing**
- Biometric check only happens when app is resumed from background
- No biometric check on fresh app launch
- No biometric check when app is just inactive (not suspended)

### ✅ **Proper State Tracking**
- Tracks if app was actually suspended (not just inactive)
- Tracks if user was authenticated when app went to background
- Only shows biometric if both conditions are met

### ✅ **Better User Experience**
- Faster app launch (no unnecessary biometric check)
- Biometric only when needed (returning from background)
- Proper session handling

## Testing Scenarios

### 1. Fresh App Launch
1. Close app completely
2. Launch app fresh
3. **Expected**: No biometric check, go directly to login/map based on session

### 2. Background to Foreground (Authenticated User)
1. Login to app
2. Put app in background (home button or switch apps)
3. Bring app back to foreground
4. **Expected**: Biometric check appears

### 3. Background to Foreground (Not Authenticated)
1. Don't login to app
2. Put app in background
3. Bring app back to foreground
4. **Expected**: No biometric check, continue normally

### 4. App Inactive (Not Suspended)
1. Open app
2. Pull down notification center (app becomes inactive but not suspended)
3. Close notification center
4. **Expected**: No biometric check

## Debug Logs

### App Launch
```
Current session on app start: exists/null
User already signed in, going to map screen
// OR
No session found, going directly to login screen
```

### App Suspended
```
AppLifecycleService: App suspended (going to background)
```

### App Resumed
```
AppLifecycleService: App resumed from background
AppLifecycleService: Was in background: true
AppLifecycleService: Was suspended: true
AppLifecycleService: Was authenticated: true
AppLifecycleService: App was suspended and user was authenticated, checking biometric...
```

## Configuration

### Biometric Settings
- **Enable Biometric**: Required for background biometric check
- **Disable Biometric**: No biometric check on resume
- **PIN Fallback**: Available if biometric fails

### App Settings
- **Background App Refresh**: Should be enabled for proper lifecycle tracking
- **Location Services**: Required for map functionality
- **Biometric Permissions**: Required for biometric authentication

## Files Modified

1. **`lib/main.dart`**
   - Removed biometric check from app launch
   - Simplified `_handleAppResumed` method
   - Updated app initialization logic

2. **`lib/services/app_lifecycle_service.dart`**
   - Added `_wasSuspended` state tracking
   - Updated resume logic to check suspension state
   - Enhanced logging for debugging

## Benefits

### Performance
- ✅ **Faster App Launch**: No biometric check on fresh launch
- ✅ **Reduced CPU Usage**: Fewer biometric operations
- ✅ **Better Battery Life**: Less frequent biometric checks

### User Experience
- ✅ **Intuitive Behavior**: Biometric only when returning from background
- ✅ **Faster Navigation**: Direct to login/map on launch
- ✅ **Proper Security**: Biometric when actually needed

### Security
- ✅ **Appropriate Timing**: Biometric check when app was suspended
- ✅ **Session Awareness**: Only check if user was authenticated
- ✅ **State Validation**: Proper state tracking and validation

The updated behavior ensures that biometric authentication is only used when the app is resumed from a suspended state, providing a better user experience while maintaining security. 