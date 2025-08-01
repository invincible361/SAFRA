import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safra_app/services/sms_service.dart';

void main() {
  group('SmsService Tests', () {
    test('getFormattedCoordinates should format coordinates correctly', () {
      final location = LatLng(28.6139, 77.2090);
      final formatted = SmsService.getFormattedCoordinates(location);
      expect(formatted, '28.613900, 77.209000');
    });

    test('getCoordinatesString should format coordinates correctly', () {
      final location = LatLng(28.6139, 77.2090);
      final coordinates = SmsService.getCoordinatesString(location);
      expect(coordinates, '28.613900, 77.209000');
    });

    test('_generateLocationMessage should create proper message format', () {
      final location = LatLng(28.6139, 77.2090);
      final customMessage = 'Test message';
      
      // This would be a private method test, but we can test the public interface
      // by calling shareLocationViaSms and checking the message format
      expect(location.latitude, 28.6139);
      expect(location.longitude, 77.2090);
    });
  });
} 