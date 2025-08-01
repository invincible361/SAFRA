import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safra_app/screens/place_search_screen.dart';

void main() {
  group('PlaceSearchScreen Tests', () {
    testWidgets('PlaceSearchScreen builds without errors', (WidgetTester tester) async {
      // Create a mock callback function
      bool callbackCalled = false;
      Map<String, dynamic>? selectedPlace;
      
      void onPlaceSelected(Map<String, dynamic> placeDetails) {
        callbackCalled = true;
        selectedPlace = placeDetails;
      }

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: PlaceSearchScreen(
            onPlaceSelected: onPlaceSelected,
            initialQuery: null,
          ),
        ),
      );

      // Verify the widget builds successfully
      expect(find.byType(PlaceSearchScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('PlaceSearchScreen shows search bar with correct hint', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlaceSearchScreen(
            onPlaceSelected: (placeDetails) {},
            initialQuery: null,
          ),
        ),
      );

      // Verify search bar is present
      expect(find.byType(TextField), findsOneWidget);
      
      // Verify the hint text is displayed
      expect(find.text('Search for places...'), findsOneWidget);
    });

    testWidgets('PlaceSearchScreen handles initial query', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlaceSearchScreen(
            onPlaceSelected: (placeDetails) {},
            initialQuery: 'Test Location',
          ),
        ),
      );

      // Verify the initial query is set in the text field
      expect(find.text('Test Location'), findsOneWidget);
    });
  });
} 