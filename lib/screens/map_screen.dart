import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../services/biometric_service.dart';
import '../services/app_lifecycle_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selector.dart';
import '../widgets/sms_share_widget.dart';
import 'street_view_screen.dart';
import 'login_screen.dart';
import 'security_setup_screen.dart';
import 'place_search_screen.dart';
import 'ai_route_selection_screen.dart';
import '../services/ai_route_service.dart';
// Add flutter_map and latlong2 for web
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;

String get googleApiKey => ApiConfig.googleMapsApiKey;

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _initialPosition;
  bool _loading = true;
  String? _error;
  Marker? _userMarker;
  Marker? _destinationMarker;
  Stream<Position>? _positionStream;
  Polyline? _routePolyline;
  final TextEditingController _destinationController = TextEditingController();
  LatLng? _currentLatLng;
  List<dynamic> _suggestions = [];
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  
  // Street View variables
  bool _isStreetViewMode = false;
  String? _streetViewUrl;
  LatLng? _streetViewLocation;
  bool _showStreetViewImage = false;
  String? _streetViewImageUrl;
  List<LatLng> _routePoints = [];

  // Add these for web at the class level
  final TextEditingController _webSearchController = TextEditingController();
  final ValueNotifier<List<Map<String, dynamic>>> _webSuggestions = ValueNotifier([]);
  final ValueNotifier<latlng.LatLng> _webMapCenter = ValueNotifier(latlng.LatLng(28.6139, 77.2090));
  final ValueNotifier<bool> _webShowSuggestions = ValueNotifier(false);
  final ValueNotifier<List<latlng.LatLng>> _webRoutePoints = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _webGeoapifyPlaces = ValueNotifier([]);
  static const geoapifyApiKey = '24e376bf13ae4bc385f36dee9a54d67a';

  // Add controllers for from/to fields
  final TextEditingController _webFromController = TextEditingController();
  final TextEditingController _webToController = TextEditingController();
  latlng.LatLng? _webFromLatLng;
  latlng.LatLng? _webToLatLng;
  final ValueNotifier<List<Map<String, dynamic>>> _webFromSuggestions = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _webToSuggestions = ValueNotifier([]);
  final ValueNotifier<bool> _webShowFromSuggestions = ValueNotifier(false);
  final ValueNotifier<bool> _webShowToSuggestions = ValueNotifier(false);

  // Sign out method
  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations?.signOut ?? 'Sign Out'),
          content: Text('${localizations?.pleaseAuthenticate ?? 'Please authenticate'}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations?.signOut ?? 'Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      try {
        // Set authentication status to false
        AppLifecycleService().setAuthenticated(false);
        await Supabase.instance.client.auth.signOut();
        print('User signed out successfully');
        // Navigate to login screen and clear the navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // This removes all previous routes from the stack
        );
      } catch (e) {
        print('Error signing out: $e');
        // Show error message if sign out fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Move these methods to the class level
  Future<void> _webFetchFromSuggestions(String query) async {
    if (query.isEmpty) {
      _webFromSuggestions.value = [];
      _webShowFromSuggestions.value = false;
      return;
    }
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=' + Uri.encodeComponent(query) + '&format=json&addressdetails=1&limit=5');
    final response = await http.get(url, headers: {'User-Agent': 'safra-app/1.0'});
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      _webFromSuggestions.value = List<Map<String, dynamic>>.from(data);
      _webShowFromSuggestions.value = true;
    }
  }
  Future<void> _webFetchToSuggestions(String query) async {
    if (query.isEmpty) {
      _webToSuggestions.value = [];
      _webShowToSuggestions.value = false;
      return;
    }
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=' + Uri.encodeComponent(query) + '&format=json&addressdetails=1&limit=5');
    final response = await http.get(url, headers: {'User-Agent': 'safra-app/1.0'});
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      _webToSuggestions.value = List<Map<String, dynamic>>.from(data);
      _webShowToSuggestions.value = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _destinationController.addListener(_onDestinationChanged);
    if (kIsWeb) {
      // On web, try to get the user's current location on map load
      Future<void> _webSetUserLocation() async {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) return;
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) return;
          }
          if (permission == LocationPermission.deniedForever) return;
          Position pos = await Geolocator.getCurrentPosition();
          _webMapCenter.value = latlng.LatLng(pos.latitude, pos.longitude);
        } catch (e) {
          // Ignore and use default center
        }
      }
      // Call this in initState
      _webSetUserLocation();
    }
  }

  @override
  void dispose() {
    _destinationController.removeListener(_onDestinationChanged);
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled. Please enable location services.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied. Please enable location permissions in settings.';
          _loading = false;
        });
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _updateUserMarker(position);
      setState(() {
        _currentLatLng = LatLng(position.latitude, position.longitude);
        _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        _loading = false;
      });
      _positionStream = Geolocator.getPositionStream();
      _positionStream?.listen(
        (pos) {
          if (mounted) {
            _updateUserMarker(pos);
            setState(() {
              _currentLatLng = LatLng(pos.latitude, pos.longitude);
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
            );
            if (_destinationMarker != null && _currentLatLng != null) {
              _drawRoute(_currentLatLng!, _destinationMarker!.position);
            }
          }
        },
        onError: (error) {
          print('Location stream error: $error');
          // Don't show error to user for stream errors, just log them
        },
      );
    } catch (e) {
      print('Location error: $e');
      // Set a default location (e.g., Bangalore) if location services fail
      setState(() {
        _error = 'Location services unavailable. Using default location.';
        _currentLatLng = const LatLng(12.9716, 77.5946); // Bangalore coordinates
        _initialPosition = const CameraPosition(
          target: LatLng(12.9716, 77.5946),
          zoom: 15,
        );
        _loading = false;
      });
    }
  }

  void _updateUserMarker(Position pos) {
    if (mounted) {
      setState(() {
        _userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(pos.latitude, pos.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      });
    }
  }

  // Street View methods
  void _toggleStreetView() {
    if (_currentLatLng != null) {
      print('Opening Street View for location: $_currentLatLng');
      _loadStreetView(_currentLatLng!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreetViewScreen(
            startLocation: _currentLatLng!,
            endLocation: _destinationMarker?.position ?? _currentLatLng!,
            routePoints: _routePoints.isNotEmpty ? _routePoints : [_currentLatLng!],
            streetViewUrl: _streetViewUrl,
            streetViewImageUrl: _streetViewImageUrl,
          ),
        ),
      );
    } else {
      print('Warning: No current location available for Street View');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location available for Street View'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _loadStreetView(LatLng location) {
    setState(() {
      _streetViewLocation = location;
      _streetViewUrl = _generateStreetViewUrl(location);
      _streetViewImageUrl = _generateStreetViewImageUrl(location);
      print('Street View URL generated: $_streetViewUrl');
      print('Street View Image URL generated: $_streetViewImageUrl');
    });
  }

  String _generateStreetViewImageUrl(LatLng location) {
    // Generate Street View static image URL with better parameters
    return 'https://maps.googleapis.com/maps/api/streetview?size=600x400&location=${location.latitude},${location.longitude}&key=$googleApiKey&heading=210&pitch=10&fov=90&source=outdoor';
  }

  void _loadStreetViewImage() {
    setState(() {
      _showStreetViewImage = !_showStreetViewImage;
      print('Show Street View Image: $_showStreetViewImage');
      if (_showStreetViewImage && _streetViewImageUrl != null) {
        print('Loading Street View image from: $_streetViewImageUrl');
        // Test the URL by making a request
        _testStreetViewUrl();
      }
    });
  }

  void _testStreetViewUrl() async {
    if (_streetViewImageUrl != null) {
      try {
        final response = await http.get(Uri.parse(_streetViewImageUrl!));
        print('Street View API response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('Street View image loaded successfully');
        } else {
          print('Street View API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error testing Street View URL: $e');
      }
    }
  }

  String _generateStreetViewUrl(LatLng location) {
    // Use Google Maps Street View URL format with proper parameters
    return 'https://www.google.com/maps/@${location.latitude},${location.longitude},3a,75y,0h,90t/data=!3m6!1e1!3m4!1s!2e0!7i16384!8i8192';
  }

  Future<void> _openStreetView() async {
    if (_streetViewUrl != null) {
      final Uri url = Uri.parse(_streetViewUrl!);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          print('Opening Street View: $_streetViewUrl');
        } else {
          print('Could not launch Street View URL: $_streetViewUrl');
          // Show a snackbar or dialog to inform the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open Street View. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error opening Street View: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening Street View: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('Street View URL is null');
    }
  }

  void _onMapTap(LatLng location) {
    if (_isStreetViewMode) {
      _loadStreetView(location);
    }
  }

  void _onDestinationChanged() async {
    final query = _destinationController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey&components=country:in',
    );
    final response = await http.get(url);
    print('Places API response: ' + response.body); // Debug print
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _suggestions = data['predictions'];
        _showSuggestions = true;
      });
    }
  }

  Future<void> _onSuggestionTap(dynamic suggestion) async {
    setState(() {
      _showSuggestions = false;
      _destinationController.text = suggestion['description'];
    });
    final placeId = suggestion['place_id'];
    final detailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleApiKey',
    );
    final detailsResponse = await http.get(detailsUrl);
    if (detailsResponse.statusCode == 200) {
      final details = json.decode(detailsResponse.body);
      final location = details['result']['geometry']['location'];
      final dest = LatLng(location['lat'], location['lng']);
      setState(() {
        _destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          position: dest,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(dest));
      if (_currentLatLng != null) {
        await _drawRoute(_currentLatLng!, dest);
      }
    }
  }

  void _openPlaceSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaceSearchScreen(
          initialQuery: _destinationController.text.isNotEmpty ? _destinationController.text : null,
          onPlaceSelected: (placeDetails) {
            _handlePlaceSelected(placeDetails);
          },
        ),
      ),
    );
  }

  void _handlePlaceSelected(Map<String, dynamic> placeDetails) {
    final geometry = placeDetails['geometry'];
    if (geometry != null && geometry['location'] != null) {
      final location = geometry['location'];
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;
      final dest = LatLng(lat, lng);
      
      setState(() {
        _destinationController.text = placeDetails['name'] ?? placeDetails['formatted_address'] ?? '';
        _destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          position: dest,
          infoWindow: InfoWindow(
            title: placeDetails['name'] ?? 'Destination',
            snippet: placeDetails['formatted_address'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      });
      
      _mapController?.animateCamera(CameraUpdate.newLatLng(dest));
      if (_currentLatLng != null) {
        _drawRoute(_currentLatLng!, dest);
      }
    }
  }

  void _openInMaps() async {
    if (_currentLatLng != null && _destinationMarker != null) {
      final startLat = _currentLatLng!.latitude;
      final startLng = _currentLatLng!.longitude;
      final endLat = _destinationMarker!.position.latitude;
      final endLng = _destinationMarker!.position.longitude;
      
      // Open in Google Maps
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving';
      
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a destination first')),
      );
    }
  }

  void _clearNavigation() {
    setState(() {
      _destinationMarker = null;
      _routePolyline = null;
      _navigationSteps.clear();
      _currentStepIndex = 0;
      _destinationController.clear();
      _suggestions.clear();
      _showSuggestions = false;
    });
    
    // Reset camera to current location
    if (_currentLatLng != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));
    }
    
    Navigator.of(context).pop(); // Close the navigation modal
  }

  void _loadStreetViewForDestination() async {
    if (_destinationMarker != null) {
      final lat = _destinationMarker!.position.latitude;
      final lng = _destinationMarker!.position.longitude;
      
      try {
        final apiKey = ApiConfig.googleMapsApiKey;
        final url = 'https://maps.googleapis.com/maps/api/streetview?size=400x300&location=$lat,$lng&key=$apiKey';
        
        setState(() {
          _streetViewUrl = url;
          _streetViewLocation = _destinationMarker!.position;
        });
      } catch (e) {
        print('Error loading street view: $e');
      }
    }
  }

  Future<void> _drawRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$googleApiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final polylineString = data['routes'][0]['overview_polyline']['points'];
        final points = _decodePolylineMobile(polylineString);
        debugPrint('Decoded polyline points: ${points.length}');
        for (int i = 0; i < (points.length < 5 ? points.length : 5); i++) {
          debugPrint('Point $i: ${points[i]}');
        }
        // Parse navigation steps
        final steps = <Map<String, dynamic>>[];
        final legs = data['routes'][0]['legs'];
        if (legs != null && legs.isNotEmpty) {
          for (final step in legs[0]['steps']) {
            steps.add({
              'instruction': (step['html_instructions'] as String?)?.replaceAll(RegExp(r'<[^>]*>'), ''),
              'distance': step['distance']?['text'] ?? '',
              'duration': step['duration']?['text'] ?? '',
            });
          }
        }
        setState(() {
          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: points, // Use all decoded points
          );
          _routePoints = points; // Store route points for Street View
          _navigationSteps = steps;
          _currentStepIndex = 0;
        });
      }
    }
  }

  List<latlng.LatLng> _decodePolylineWeb(String encoded) {
    List<latlng.LatLng> polyline = [];
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
      polyline.add(latlng.LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  List<LatLng> _decodePolylineMobile(String encoded) {
    List<LatLng> polyline = [];
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
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  bool _isValidLatLng(latlng.LatLng? point) {
    if (point == null) return false;
    if (!point.latitude.isFinite || !point.longitude.isFinite) return false;
    if (point.latitude.abs() > 90 || point.longitude.abs() > 180) return false;
    return true;
  }

  // Helper to validate and log invalid LatLng
  latlng.LatLng? _safeLatLng(dynamic lat, dynamic lon, {String? context}) {
    if (lat is num && lon is num && lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180) {
      return latlng.LatLng(lat.toDouble(), lon.toDouble());
    } else {
      debugPrint('Invalid LatLng: lat=$lat, lon=$lon, context=$context');
      return null;
    }
  }

  Future<void> _startInAppNavigation() async {
    if (_destinationMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a destination first')),
      );
      return;
    }

    // Ensure we have a computed route and steps
    if ((_routePolyline == null || _navigationSteps.isEmpty) && _currentLatLng != null) {
      await _drawRoute(_currentLatLng!, _destinationMarker!.position);
    }

    // Open in-app navigation modal
    if (mounted) {
      _showNavigationModal();
    }
  }

  void _openAIRouteSelection() async {
    if (_destinationMarker != null) {
      final destination = _destinationMarker!.position;
      final currentLocation = _currentLatLng ?? const LatLng(0, 0);
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIRouteSelectionScreen(
            origin: currentLocation,
            destination: destination,
            destinationName: _destinationController.text,
          ),
        ),
      );
      
      if (result != null && result is RouteOption) {
        // Handle selected AI route
        _handleSelectedAIRoute(result);
      }
    }
  }

  void _handleSelectedAIRoute(RouteOption route) {
    // Update the map with the selected AI route
    setState(() {
      _routePoints = route.routePoints;
      _navigationSteps = _convertRouteToSteps(route);
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${route.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Map<String, dynamic>> _convertRouteToSteps(RouteOption route) {
    // Convert AI route to navigation steps format
    return [
      {
        'instruction': 'Start from your current location',
        'distance': '0 km',
        'duration': '0 min',
      },
      {
        'instruction': 'Follow ${route.name}',
        'distance': '${route.distance.toStringAsFixed(1)} km',
        'duration': '${route.duration} min',
      },
      {
        'instruction': 'Arrive at destination',
        'distance': '0 km',
        'duration': '0 min',
      },
    ];
  }

  void _showNavigationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFF111416),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Route Progress Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                                         Text(
                       AppLocalizations.of(context)?.routeProgress ?? 'ROUTE PROGRESS',
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                         color: Colors.black,
                       ),
                     ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                                                 Text(
                           AppLocalizations.of(context)?.currentLocation ?? 'Current Location',
                           style: const TextStyle(
                             color: Colors.black,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         Text(
                           AppLocalizations.of(context)?.destination ?? 'Destination',
                           style: const TextStyle(
                             color: Colors.black,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                      ],
                    ),
                    const SizedBox(height: 8),
                                         Text(
                       '${AppLocalizations.of(context)?.steps ?? 'Steps'} ${_currentStepIndex + 1}/${_navigationSteps.length}',
                       style: const TextStyle(
                         color: Colors.black,
                         fontSize: 14,
                       ),
                     ),
                  ],
                ),
              ),
              
              // Navigation Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Street View or Map Display
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isStreetViewMode && _streetViewUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _streetViewUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.streetview,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.map,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      
                      // Navigation Controls
                      Positioned(
                        left: 8,
                        top: 8,
                        child: IconButton(
                          onPressed: _currentStepIndex > 0
                              ? () => setState(() => _currentStepIndex--)
                              : null,
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          onPressed: _currentStepIndex < _navigationSteps.length - 1
                              ? () => setState(() => _currentStepIndex++)
                              : null,
                          icon: const Icon(Icons.arrow_forward, color: Colors.black),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      
                      // Street View Toggle Button
                      Positioned(
                        right: 8,
                        top: 60,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _isStreetViewMode = !_isStreetViewMode;
                            });
                            if (_isStreetViewMode && _destinationMarker != null) {
                              _loadStreetViewForDestination();
                            }
                          },
                          icon: Icon(
                            _isStreetViewMode ? Icons.map : Icons.streetview,
                            color: Colors.black,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      
                      // Zoom Controls
                      Positioned(
                        right: 8,
                        top: 120,
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Zoom in functionality
                              },
                              icon: const Icon(Icons.zoom_in, color: Colors.black),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Zoom out functionality
                              },
                              icon: const Icon(Icons.zoom_out, color: Colors.black),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Navigation Buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Top Row: Previous/Next
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentStepIndex > 0
                                ? () => setState(() => _currentStepIndex--)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF87CEEB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                                                         child: Text(
                               AppLocalizations.of(context)?.previous ?? 'PREVIOUS',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentStepIndex < _navigationSteps.length - 1
                                ? () => setState(() => _currentStepIndex++)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4169E1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                                                         child: Text(
                               AppLocalizations.of(context)?.next ?? 'NEXT',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bottom Row: Open in Maps/Clear
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _openInMaps,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                                                         child: Text(
                               AppLocalizations.of(context)?.openInMaps ?? 'OPEN IN MAPS',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearNavigation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                                                         child: Text(
                               AppLocalizations.of(context)?.clear ?? 'CLEAR',
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // --- Web: Place search state ---
      Future<void> _webFetchSuggestions(String query) async {
        if (query.isEmpty) {
          _webSuggestions.value = [];
          _webShowSuggestions.value = false;
          _webRoutePoints.value = [];
          return;
        }
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=' + Uri.encodeComponent(query) + '&format=json&addressdetails=1&limit=5');
        final response = await http.get(url, headers: {'User-Agent': 'safra-app/1.0'});
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          _webSuggestions.value = List<Map<String, dynamic>>.from(data);
          _webShowSuggestions.value = true;
        }
      }

      Future<void> _webFetchRoute(latlng.LatLng start, latlng.LatLng end) async {
        // Use OSRM for routing
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final coords = data['routes'][0]['geometry']['coordinates'] as List;
            final List<latlng.LatLng> validPoints = [];
            for (final c in coords) {
              final lat = c[1];
              final lon = c[0];
              final point = _safeLatLng(lat, lon, context: 'route');
              if (point != null) validPoints.add(point);
            }
            // Final check: only assign if all points are valid and finite
            if (validPoints.isNotEmpty && validPoints.every((p) => p.latitude.isFinite && p.longitude.isFinite && p.latitude.abs() <= 90 && p.longitude.abs() <= 180)) {
              _webRoutePoints.value = validPoints;
            } else {
              _webRoutePoints.value = [];
            }
          } else {
            _webRoutePoints.value = [];
          }
        }
      }
      // Remove Geoapify integration for web places, use Nominatim for all place search
      Future<void> _webFetchNominatimPlaces(String query) async {
        if (query.isEmpty) {
          _webGeoapifyPlaces.value = [];
          return;
        }
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=' + Uri.encodeComponent(query) + '&format=json&addressdetails=1&limit=20');
        final response = await http.get(url, headers: {'User-Agent': 'safra-app/1.0'});
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          _webGeoapifyPlaces.value = data.map<Map<String, dynamic>>((item) => {
            'name': item['display_name'] ?? '',
            'lat': double.tryParse(item['lat'] ?? '0') ?? 0,
            'lon': double.tryParse(item['lon'] ?? '0') ?? 0,
            'address': item['display_name'] ?? '',
          }).toList();
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.map ?? 'Map'),
          actions: [
            const LanguageSelector(),
            IconButton(
              icon: const Icon(Icons.security),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecuritySetupScreen(),
                  ),
                );
              },
              tooltip: AppLocalizations.of(context)?.securitySettings ?? 'Security Settings',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: AppLocalizations.of(context)?.signOut ?? 'Sign Out',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('From:'),
                            TextField(
                              controller: _webFromController,
                              decoration: const InputDecoration(
                                hintText: 'Start location',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Colors.black),
                              onChanged: (q) => _webFetchFromSuggestions(q),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: _webShowFromSuggestions,
                              builder: (context, show, _) {
                                if (!show || _webFromSuggestions.value.isEmpty) return const SizedBox.shrink();
                                return Container(
                                  color: Colors.white,
                                  height: 120,
                                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                                    valueListenable: _webFromSuggestions,
                                    builder: (context, suggestions, _) {
                                      return ListView.builder(
                                        itemCount: suggestions.length,
                                        itemBuilder: (context, index) {
                                          final s = suggestions[index];
                                          return ListTile(
                                            title: Text(
                                              s['display_name'] ?? '',
                                              style: const TextStyle(color: Colors.black),
                                            ),
                                            onTap: () {
                                              final latRaw = s['lat'] ?? '0';
                                              final lonRaw = s['lon'] ?? '0';
                                              final lat = double.tryParse(latRaw) ?? 0;
                                              final lon = double.tryParse(lonRaw) ?? 0;
                                              if (lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180) {
                                                _webFromLatLng = latlng.LatLng(lat, lon);
                                              } else {
                                                _webFromLatLng = null;
                                              }
                                              _webFromController.text = s['display_name'] ?? '';
                                              _webShowFromSuggestions.value = false;
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('To:'),
                            TextField(
                              controller: _webToController,
                              decoration: const InputDecoration(
                                hintText: 'Destination',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Colors.black),
                              onChanged: (q) => _webFetchToSuggestions(q),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: _webShowToSuggestions,
                              builder: (context, show, _) {
                                if (!show || _webToSuggestions.value.isEmpty) return const SizedBox.shrink();
                                return Container(
                                  color: Colors.white,
                                  height: 120,
                                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                                    valueListenable: _webToSuggestions,
                                    builder: (context, suggestions, _) {
                                      return ListView.builder(
                                        itemCount: suggestions.length,
                                        itemBuilder: (context, index) {
                                          final s = suggestions[index];
                                          return ListTile(
                                            title: Text(
                                              s['display_name'] ?? '',
                                              style: const TextStyle(color: Colors.black),
                                            ),
                                            onTap: () {
                                              final latRaw = s['lat'] ?? '0';
                                              final lonRaw = s['lon'] ?? '0';
                                              final lat = double.tryParse(latRaw) ?? 0;
                                              final lon = double.tryParse(lonRaw) ?? 0;
                                              if (lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180) {
                                                _webToLatLng = latlng.LatLng(lat, lon);
                                              } else {
                                                _webToLatLng = null;
                                              }
                                              _webToController.text = s['display_name'] ?? '';
                                              _webShowToSuggestions.value = false;
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_isValidLatLng(_webFromLatLng) && _isValidLatLng(_webToLatLng)) {
                            _webFetchRoute(_webFromLatLng!, _webToLatLng!);
                            _webMapCenter.value = _webFromLatLng!;
                          }
                        },
                        child: const Text('Get Directions'),
                      ),
                    ],
                  ),
                  ValueListenableBuilder<latlng.LatLng>(
                    valueListenable: _webMapCenter,
                    builder: (context, center, _) {
                      if (!_isValidLatLng(center) || _safeLatLng(center.latitude, center.longitude, context: 'center') == null) {
                        debugPrint('Invalid map center: $center');
                        return const Center(child: Text('Invalid map center. Please select valid locations.'));
                      }
                      return ValueListenableBuilder<List<latlng.LatLng>>(
                        valueListenable: _webRoutePoints,
                        builder: (context, routePoints, _) {
                          // Filter out invalid route points
                          final validRoutePoints = routePoints.where((p) => _isValidLatLng(p)).toList();
                          return fm.FlutterMap(
                            options: fm.MapOptions(
                              center: center,
                              zoom: 13.0,
                              onTap: (tapPos, latlng) {
                                _webShowSuggestions.value = false;
                              },
                            ),
                            children: [
                              fm.TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              // Show Nominatim places as markers
                              ValueListenableBuilder<List<Map<String, dynamic>>>(
                                valueListenable: _webGeoapifyPlaces,
                                builder: (context, places, _) {
                                  return fm.MarkerLayer(
                                    markers: [
                                      ...places.map((place) {
                                        final markerPoint = _safeLatLng(place['lat'], place['lon'], context: 'marker');
                                        if (markerPoint == null) return null;
                                        return fm.Marker(
                                          point: markerPoint,
                                          width: 40,
                                          height: 40,
                                          child: Tooltip(
                                            message: place['name'] ?? '',
                                            child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                                          ),
                                        );
                                      }).whereType<fm.Marker>(),
                                      // ... existing center marker ...
                                      fm.Marker(
                                        point: center,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                      ),
                                      // Show markers for from/to
                                      if (_safeLatLng(_webFromLatLng?.latitude, _webFromLatLng?.longitude, context: 'from') != null)
                                        fm.Marker(
                                          point: _webFromLatLng!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_pin, color: Colors.green, size: 40),
                                        ),
                                      if (_safeLatLng(_webToLatLng?.latitude, _webToLatLng?.longitude, context: 'to') != null)
                                        fm.Marker(
                                          point: _webToLatLng!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              // Only draw polyline if valid
                              if (validRoutePoints.length > 1)
                                fm.PolylineLayer(
                                  polylines: [
                                    fm.Polyline(
                                      points: validRoutePoints,
                                      color: Colors.blue,
                                      strokeWidth: 4.0,
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  // ... existing suggestion dropdown ...
                ],
              ),
                                ),
                    // Street View Widget
                    if (_isStreetViewMode && _streetViewUrl != null)
                      Container(
                        height: 250,
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Embedded Street View
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      // Street View content
                                      _showStreetViewImage && _streetViewImageUrl != null
                                          ? Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _streetViewImageUrl!,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            CircularProgressIndicator(
                                                              value: loadingProgress.expectedTotalBytes != null
                                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                                      loadingProgress.expectedTotalBytes!
                                                                  : null,
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Text(
                                                              'Loading Street View...',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.error,
                                                              size: 48,
                                                              color: Colors.red[600],
                                                            ),
                                                            const SizedBox(height: 8),
                                                            Text(
                                                              'Failed to load Street View',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.red[600],
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              'No Street View available at this location',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                              ),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: Colors.grey[300],
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.streetview,
                                                      size: 48,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Street View',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Location: ${_streetViewLocation?.latitude.toStringAsFixed(4)}, ${_streetViewLocation?.longitude.toStringAsFixed(4)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          onPressed: _openStreetView,
                                                          icon: const Icon(Icons.open_in_new),
                                                          label: const Text('Open in Maps'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.blue,
                                                            foregroundColor: Colors.white,
                                                          ),
                                                        ),
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            if (_streetViewLocation != null) {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => StreetViewScreen(
                                                                    startLocation: _currentLatLng ?? _streetViewLocation!,
                                                                    endLocation: _destinationMarker?.position ?? _streetViewLocation!,
                                                                    routePoints: _routePoints.isNotEmpty ? _routePoints : [_streetViewLocation!],
                                                                    streetViewUrl: _streetViewUrl,
                                                                    streetViewImageUrl: _streetViewImageUrl,
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          icon: const Icon(Icons.image),
                                                          label: const Text('Show Image'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green,
                                                            foregroundColor: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                              // Close button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _toggleStreetView,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_navigationSteps.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigate'),
                          onPressed: _showNavigationModal,
                        ),
                      ),
          ],
        ),
      );
    }
    // --- Mobile: Google Maps ---
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecuritySetupScreen(),
                ),
              );
            },
            tooltip: 'Security Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _destinationController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter destination',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                  ),
                                  style: const TextStyle(color: Colors.black), // Make input text black
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _openPlaceSearch(),
                                icon: const Icon(Icons.search, color: Colors.blue),
                                tooltip: 'Search Places',
                              ),
                            ],
                          ),
                          if (_showSuggestions && _suggestions.isNotEmpty)
                            Container(
                              color: Colors.white,
                              height: 200,
                              child: ListView.builder(
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = _suggestions[index];
                                  return ListTile(
                                    title: Text(
                                      suggestion['description'],
                                      style: const TextStyle(color: Colors.black), // Make suggestion text black
                                    ),
                                    onTap: () => _onSuggestionTap(suggestion),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: _initialPosition!,
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                            onTap: _onMapTap,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: {
                              if (_userMarker != null) _userMarker!,
                              if (_destinationMarker != null) _destinationMarker!,
                            },
                            polylines: _routePolyline != null ? {_routePolyline!} : {},
                          ),
                          // Street View Toggle Button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: FloatingActionButton(
                              onPressed: _toggleStreetView,
                              backgroundColor: _isStreetViewMode ? Colors.orange : Colors.blue,
                              child: Icon(
                                _isStreetViewMode ? Icons.map : Icons.streetview,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // SMS Share Button
                          Positioned(
                            top: 16,
                            left: 16,
                            child: FloatingActionButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => SmsShareWidget(
                                    currentLocation: _currentLatLng,
                                    title: AppLocalizations.of(context)?.shareLocation ?? 'Share Location',
                                  ),
                                );
                              },
                              backgroundColor: Colors.green,
                              child: const Icon(
                                Icons.share_location,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Search Places Button
                          Positioned(
                            top: 80,
                            left: 16,
                            child: FloatingActionButton(
                              onPressed: _openPlaceSearch,
                              backgroundColor: const Color(0xFFCAE3F2),
                              child: const Icon(
                                Icons.search,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_destinationMarker != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // AI Route Selection Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _destinationMarker != null ? _openAIRouteSelection : null,
                                icon: const Icon(Icons.psychology, color: Colors.white),
                                label: Text(
                                  '🤖 AI Route Selection',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _destinationMarker != null 
                                      ? const Color(0xFF9C27B0) 
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Navigation Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _destinationMarker != null ? _startInAppNavigation : null,
                                icon: const Icon(Icons.navigation, color: Colors.white),
                                label: Text(
                                  AppLocalizations.of(context)?.startNavigation ?? 'Start Navigation',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _destinationMarker != null 
                                      ? const Color(0xFF4169E1) 
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Detailed Navigation Button (if route is calculated)
                            if (_navigationSteps.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _showNavigationModal,
                                  icon: const Icon(Icons.directions, color: Colors.white),
                                  label: Text(
                                    AppLocalizations.of(context)?.viewDirections ?? 'View Directions',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            if (_navigationSteps.isNotEmpty) const SizedBox(height: 8),
                            // Street View Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _toggleStreetView,
                                icon: Icon(
                                  _isStreetViewMode ? Icons.map : Icons.streetview,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  _isStreetViewMode 
                                      ? (AppLocalizations.of(context)?.switchToMap ?? 'Switch to Map')
                                      : (AppLocalizations.of(context)?.streetView ?? 'Street View'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isStreetViewMode 
                                      ? Colors.orange 
                                      : const Color(0xFFCAE3F2),
                                  foregroundColor: _isStreetViewMode ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
} 