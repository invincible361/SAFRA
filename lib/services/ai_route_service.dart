import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

class RouteOption {
  final String id;
  final String name;
  final String description;
  final int duration; // in minutes
  final double distance; // in km
  final String trafficLevel; // low, medium, high
  final String congestionLevel; // low, medium, high
  final List<LatLng> routePoints;
  final String polyline;
  final Map<String, dynamic> analysis;

  RouteOption({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.distance,
    required this.trafficLevel,
    required this.congestionLevel,
    required this.routePoints,
    required this.polyline,
    required this.analysis,
  });
}

class AIRouteService {
  static const String _googleDirectionsApi = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _openAiApi = 'https://api.openai.com/v1/chat/completions';
  
  static String get _openAiKey => ApiConfig.openAiApiKey;
  
  /// Generate multiple route options with AI analysis
  static Future<List<RouteOption>> generateRouteOptions({
    required LatLng origin,
    required LatLng destination,
    String? googleApiKey,
  }) async {
    try {
      // Get multiple routes from Google Directions API
      final routes = await _getMultipleRoutes(origin, destination, googleApiKey);
      
      // Analyze routes with AI
      final analyzedRoutes = await _analyzeRoutesWithAI(routes, origin, destination);
      
      return analyzedRoutes;
    } catch (e) {
      print('Error generating route options: $e');
      return [];
    }
  }

  /// Get multiple route alternatives from Google Directions API
  static Future<List<Map<String, dynamic>>> _getMultipleRoutes(
    LatLng origin,
    LatLng destination,
    String? apiKey,
  ) async {
    final List<Map<String, dynamic>> routes = [];
    
    // Try different travel modes and alternatives
    final modes = ['driving', 'transit', 'walking'];
    
    for (final mode in modes) {
      try {
        final url = Uri.parse('$_googleDirectionsApi?'
            'origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&mode=$mode'
            '&alternatives=true'
            '&key=$apiKey');
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['routes'] != null) {
            for (final route in data['routes']) {
              routes.add({
                'mode': mode,
                'route': route,
                'legs': route['legs'],
                'overview_polyline': route['overview_polyline'],
              });
            }
          }
        }
      } catch (e) {
        print('Error getting route for mode $mode: $e');
      }
    }
    
    return routes;
  }

  /// Analyze routes using AI to provide intelligent recommendations
  static Future<List<RouteOption>> _analyzeRoutesWithAI(
    List<Map<String, dynamic>> routes,
    LatLng origin,
    LatLng destination,
  ) async {
    final List<RouteOption> analyzedRoutes = [];
    
    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final legs = route['legs'] as List;
      
      if (legs.isNotEmpty) {
        final leg = legs[0];
        final duration = (leg['duration']['value'] as int) ~/ 60; // Convert to minutes
        final distance = (leg['distance']['value'] as int) / 1000; // Convert to km
        
        // Generate AI analysis
        final analysis = await _generateAIAnalysis(
          route,
          duration,
          distance,
          origin,
          destination,
        );
        
        // Decode polyline
        final polyline = route['overview_polyline']['points'] as String;
        final routePoints = _decodePolyline(polyline);
        
        // Create route option
        final routeOption = RouteOption(
          id: 'route_$i',
          name: _generateRouteName(analysis, i),
          description: analysis['description'] ?? '',
          duration: duration,
          distance: distance,
          trafficLevel: analysis['traffic_level'] ?? 'medium',
          congestionLevel: analysis['congestion_level'] ?? 'medium',
          routePoints: routePoints,
          polyline: polyline,
          analysis: analysis,
        );
        
        analyzedRoutes.add(routeOption);
      }
    }
    
    // Sort routes by AI recommendation score
    analyzedRoutes.sort((a, b) {
      final scoreA = a.analysis['recommendation_score'] ?? 0.0;
      final scoreB = b.analysis['recommendation_score'] ?? 0.0;
      return scoreB.compareTo(scoreA);
    });
    
    return analyzedRoutes;
  }

  /// Generate AI analysis for a route
  static Future<Map<String, dynamic>> _generateAIAnalysis(
    Map<String, dynamic> route,
    int duration,
    double distance,
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final prompt = '''
Analyze this route and provide intelligent recommendations:

Route Details:
- Duration: $duration minutes
- Distance: ${distance.toStringAsFixed(1)} km
- Mode: ${route['mode']}
- Steps: ${_extractRouteSteps(route)}

Please provide analysis in JSON format with the following fields:
- traffic_level: "low", "medium", or "high" based on route characteristics
- congestion_level: "low", "medium", or "high" based on urban density
- description: Brief description of the route (max 100 characters)
- pros: Array of 2-3 advantages of this route
- cons: Array of 2-3 disadvantages of this route
- recommendation_score: Float between 0.0 and 1.0
- route_type: "fastest", "scenic", "efficient", "avoid_traffic", or "eco_friendly"
- estimated_traffic_delay: Estimated delay in minutes due to traffic
- safety_score: Float between 0.0 and 1.0 for route safety
- accessibility_score: Float between 0.0 and 1.0 for accessibility

Consider factors like:
- Time of day patterns
- Urban vs suburban areas
- Public transport availability
- Road types and conditions
- Historical traffic patterns
''';

      final response = await http.post(
        Uri.parse(_openAiApi),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an AI route optimization expert. Provide detailed analysis in JSON format only.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          return json.decode(jsonMatch.group(0)!);
        }
      }
    } catch (e) {
      print('Error generating AI analysis: $e');
    }
    
    // Fallback analysis
    return _generateFallbackAnalysis(route, duration, distance);
  }

  /// Extract route steps for AI analysis
  static String _extractRouteSteps(Map<String, dynamic> route) {
    final legs = route['legs'] as List;
    if (legs.isEmpty) return '';
    
    final steps = legs[0]['steps'] as List;
    return steps.take(5).map((step) => step['html_instructions']).join(', ');
  }

  /// Generate fallback analysis when AI is unavailable
  static Map<String, dynamic> _generateFallbackAnalysis(
    Map<String, dynamic> route,
    int duration,
    double distance,
  ) {
    final mode = route['mode'] as String;
    
    String trafficLevel = 'medium';
    String congestionLevel = 'medium';
    String description = '';
    List<String> pros = [];
    List<String> cons = [];
    double recommendationScore = 0.5;
    String routeType = 'efficient';
    
    switch (mode) {
      case 'driving':
        trafficLevel = duration > 30 ? 'high' : 'medium';
        congestionLevel = distance < 5 ? 'high' : 'medium';
        description = 'Direct driving route';
        pros = ['Fastest option', 'Door-to-door'];
        cons = ['Traffic dependent', 'Parking needed'];
        recommendationScore = 0.7;
        routeType = 'fastest';
        break;
      case 'transit':
        trafficLevel = 'low';
        congestionLevel = 'medium';
        description = 'Public transport route';
        pros = ['No traffic worries', 'Cost effective'];
        cons = ['Fixed schedules', 'Walking required'];
        recommendationScore = 0.6;
        routeType = 'eco_friendly';
        break;
      case 'walking':
        trafficLevel = 'low';
        congestionLevel = 'low';
        description = 'Walking route';
        pros = ['No traffic', 'Healthy option'];
        cons = ['Time consuming', 'Weather dependent'];
        recommendationScore = distance < 2 ? 0.8 : 0.3;
        routeType = 'scenic';
        break;
    }
    
    return {
      'traffic_level': trafficLevel,
      'congestion_level': congestionLevel,
      'description': description,
      'pros': pros,
      'cons': cons,
      'recommendation_score': recommendationScore,
      'route_type': routeType,
      'estimated_traffic_delay': trafficLevel == 'high' ? 15 : 5,
      'safety_score': 0.8,
      'accessibility_score': 0.7,
    };
  }

  /// Generate route name based on analysis
  static String _generateRouteName(Map<String, dynamic> analysis, int index) {
    final routeType = analysis['route_type'] ?? 'efficient';
    final trafficLevel = analysis['traffic_level'] ?? 'medium';
    
    switch (routeType) {
      case 'fastest':
        return '🚗 Fastest Route';
      case 'scenic':
        return '🌳 Scenic Route';
      case 'efficient':
        return '⚡ Efficient Route';
      case 'avoid_traffic':
        return '🚦 Low Traffic Route';
      case 'eco_friendly':
        return '🌱 Eco-Friendly Route';
      default:
        return 'Route ${index + 1}';
    }
  }

  /// Decode Google polyline
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  /// Get route recommendations based on user preferences
  static List<RouteOption> getRecommendations(
    List<RouteOption> routes,
    Map<String, dynamic> preferences,
  ) {
    final List<RouteOption> recommendations = [];
    
    for (final route in routes) {
      double score = 0.0;
      
      // Preference scoring
      if (preferences['prefer_fastest'] == true && route.analysis['route_type'] == 'fastest') {
        score += 0.3;
      }
      if (preferences['prefer_eco_friendly'] == true && route.analysis['route_type'] == 'eco_friendly') {
        score += 0.3;
      }
      if (preferences['avoid_traffic'] == true && route.trafficLevel == 'low') {
        score += 0.2;
      }
      if (preferences['prefer_scenic'] == true && route.analysis['route_type'] == 'scenic') {
        score += 0.2;
      }
      
      // Duration preference
      final maxDuration = preferences['max_duration'] ?? 60;
      if (route.duration <= maxDuration) {
        score += 0.1;
      }
      
      // Safety preference
      final safetyScore = route.analysis['safety_score'] ?? 0.5;
      if (preferences['prefer_safe'] == true && safetyScore > 0.7) {
        score += 0.1;
      }
      
      if (score > 0.0) {
        recommendations.add(route);
      }
    }
    
    recommendations.sort((a, b) => b.analysis['recommendation_score'].compareTo(a.analysis['recommendation_score']));
    return recommendations;
  }
} 