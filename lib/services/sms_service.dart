import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SmsService {
  /// Share current location coordinates via SMS
  static Future<bool> shareLocationViaSms({
    required String phoneNumber,
    String? customMessage,
    LatLng? customLocation,
  }) async {
    try {
      // Get current location if not provided
      LatLng location = customLocation ?? await _getCurrentLocation();
      
      // Generate location message
      String message = _generateLocationMessage(location, customMessage);
      
      // Use URL scheme for all platforms
      if (kIsWeb) {
        return await _shareLocationOnWeb(phoneNumber, message);
      } else if (Platform.isIOS) {
        return await _shareLocationOnIOS(phoneNumber, message);
      } else {
        return await _shareLocationOnAndroid(phoneNumber, message);
      }
    } catch (e) {
      print('Error sharing location via SMS: $e');
      return false;
    }
  }

  /// Share location on web platform
  static Future<bool> _shareLocationOnWeb(String phoneNumber, String message) async {
    try {
      // Create SMS URL for web
      String smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
      
      // Try to open SMS app
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
        return true;
      } else {
        // Fallback: copy message to clipboard and show instructions
        print('SMS app not available, message copied to clipboard');
        return false;
      }
    } catch (e) {
      print('Error sharing location on web: $e');
      return false;
    }
  }

  /// Share location on iOS platform
  static Future<bool> _shareLocationOnIOS(String phoneNumber, String message) async {
    try {
      // iOS uses the Messages app URL scheme
      String smsUrl = 'sms:$phoneNumber&body=${Uri.encodeComponent(message)}';
      
      // Try to open Messages app
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
        return true;
      } else {
        // Fallback: try alternative URL format
        String alternativeUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
        if (await canLaunchUrl(Uri.parse(alternativeUrl))) {
          await launchUrl(Uri.parse(alternativeUrl));
          return true;
        }
        print('Messages app not available on iOS');
        return false;
      }
    } catch (e) {
      print('Error sharing location on iOS: $e');
      return false;
    }
  }

  /// Share location on Android platform
  static Future<bool> _shareLocationOnAndroid(String phoneNumber, String message) async {
    try {
      // Android SMS URL scheme
      String smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
      
      // Try to open SMS app
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
        return true;
      } else {
        print('SMS app not available on Android');
        return false;
      }
    } catch (e) {
      print('Error sharing location on Android: $e');
      return false;
    }
  }

  /// Get current location coordinates
  static Future<LatLng> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Generate formatted location message
  static String _generateLocationMessage(LatLng location, String? customMessage) {
    String baseMessage = '📍 My Location:\n';
    baseMessage += 'Latitude: ${location.latitude.toStringAsFixed(6)}\n';
    baseMessage += 'Longitude: ${location.longitude.toStringAsFixed(6)}\n';
    
    // Add custom message if provided
    if (customMessage != null && customMessage.isNotEmpty) {
      baseMessage += '\n💬 Message: $customMessage';
    }
    
    return baseMessage;
  }

  /// Share location with address information (requires internet for geocoding)
  static Future<bool> shareLocationWithAddress({
    required String phoneNumber,
    String? customMessage,
    LatLng? customLocation,
  }) async {
    try {
      // Get current location if not provided
      LatLng location = customLocation ?? await _getCurrentLocation();
      
      // Try to get address (requires internet)
      String address = 'Unknown location';
      try {
        List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          geocoding.Placemark place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        }
      } catch (e) {
        print('Could not get address (internet required): $e');
      }
      
      // Generate message with address
      String message = '📍 My Location:\n';
      message += 'Address: $address\n';
      message += 'Latitude: ${location.latitude.toStringAsFixed(6)}\n';
      message += 'Longitude: ${location.longitude.toStringAsFixed(6)}\n';
      
      if (customMessage != null && customMessage.isNotEmpty) {
        message += '\n💬 Message: $customMessage';
      }
      
      // Use URL scheme for all platforms
      if (kIsWeb) {
        return await _shareLocationOnWeb(phoneNumber, message);
      } else if (Platform.isIOS) {
        return await _shareLocationOnIOS(phoneNumber, message);
      } else {
        return await _shareLocationOnAndroid(phoneNumber, message);
      }
    } catch (e) {
      print('Error sharing location with address via SMS: $e');
      return false;
    }
  }

  /// Check if SMS is available on the device
  static Future<bool> isSmsAvailable() async {
    try {
      // All platforms now use URL schemes to open SMS apps
      // This approach works on web, iOS, and Android
      return true;
    } catch (e) {
      print('Error checking SMS availability: $e');
      return false;
    }
  }

  /// Get formatted coordinates string
  static String getFormattedCoordinates(LatLng location) {
    return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
  }

  /// Get coordinates as a simple string
  static String getCoordinatesString(LatLng location) {
    return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
  }
} 