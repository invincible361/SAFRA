# SMS Coordinate Sharing Feature

## Overview

The SAFRA app now includes the ability to share location coordinates via SMS without requiring an internet connection. This feature is particularly useful in emergency situations or areas with poor internet connectivity.

## Features

### ✅ **Works Without Internet**
- Share coordinates via SMS without internet connection
- Only requires cellular network for SMS delivery
- GPS coordinates are obtained locally from device

### ✅ **Multiple Sharing Options**
- **Basic Coordinates**: Share latitude/longitude with Google Maps link
- **With Address**: Include street address (requires internet for geocoding)
- **Custom Messages**: Add personal messages to location shares

### ✅ **Cross-Platform Support**
- Works on both Android and iOS devices
- Supports multiple languages (English, Hindi, Kannada)

## How It Works

### 1. **Location Acquisition**
- Uses device GPS to get current coordinates
- No internet required for location detection
- High-accuracy positioning

### 2. **Message Format**
```
📍 My Location:
Latitude: 28.613900
Longitude: 77.209000
🗺️ Maps: https://maps.google.com/?q=28.6139,77.2090

💬 Message: [Custom message if provided]
```

### 3. **SMS Delivery**
- Sends via device's SMS capability
- Works with any phone number
- No app installation required for recipient

## Usage Instructions

### For Users:

1. **Open the Map Screen**
   - Navigate to the main map view

2. **Tap the Share Button**
   - Green location share button (top-left corner)
   - Icon: 📍

3. **Enter Recipient Details**
   - Phone number (with country code)
   - Optional custom message
   - Choose to include address (requires internet)

4. **Send SMS**
   - Tap "Share" to send
   - SMS will be sent immediately

### For Recipients:

1. **Receive SMS**
   - Standard SMS message with coordinates
   - No app installation required

2. **View Location**
   - Copy coordinates to any mapping app
   - Click Google Maps link (when online)
   - Use coordinates in GPS devices

## Technical Implementation

### Dependencies Added:
```yaml
flutter_sms: ^2.3.3
permission_handler: ^11.3.1
```

### Key Components:

1. **SmsService** (`lib/services/sms_service.dart`)
   - Handles SMS permissions
   - Generates formatted messages
   - Manages location acquisition

2. **SmsShareWidget** (`lib/widgets/sms_share_widget.dart`)
   - User interface for sharing
   - Input validation
   - Error handling

3. **Map Integration** (`lib/screens/map_screen.dart`)
   - Share button in map interface
   - Current location access

### Permissions Required:
```xml
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
```

## Benefits

### ✅ **Emergency Use**
- Share location during emergencies
- Works without internet
- Immediate delivery

### ✅ **Remote Areas**
- Share coordinates in areas with poor connectivity
- GPS works anywhere with satellite coverage
- SMS works with basic cellular signal

### ✅ **Universal Compatibility**
- Recipients don't need the app
- Works with any phone
- Standard SMS format

### ✅ **Privacy**
- Direct SMS (not through servers)
- No data stored on external servers
- User controls when to share

## Limitations

### ⚠️ **Address Lookup**
- Street addresses require internet connection
- Geocoding needs online services
- Coordinates work offline

### ⚠️ **SMS Costs**
- Standard SMS charges apply
- International rates for overseas numbers
- Carrier-dependent pricing

### ⚠️ **Device Requirements**
- Requires SMS capability
- GPS must be enabled
- Location permissions needed

## Testing

Run the SMS service tests:
```bash
flutter test test/sms_service_test.dart
```

## Future Enhancements

- [ ] Add support for multiple recipients
- [ ] Include estimated accuracy information
- [ ] Add timestamp to shared coordinates
- [ ] Support for sharing saved locations
- [ ] Integration with emergency contacts

## Troubleshooting

### Common Issues:

1. **SMS Permission Denied**
   - Go to Settings > Apps > SAFRA > Permissions
   - Enable SMS permission

2. **Location Not Available**
   - Enable GPS in device settings
   - Grant location permissions to app

3. **SMS Not Sending**
   - Check cellular signal
   - Verify phone number format
   - Ensure SMS capability on device

### Support:
For technical issues, check the app logs or contact support through the app's help section. 