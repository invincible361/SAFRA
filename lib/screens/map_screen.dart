import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../services/app_lifecycle_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_selector.dart';
import '../widgets/sms_share_widget.dart';
import 'street_view_screen.dart';
import 'login_screen.dart';
import 'security_setup_screen.dart';
import 'place_search_screen.dart';
import 'ai_route_selection_screen.dart';
import 'custom_path_screen.dart';
import '../services/ai_route_service.dart';
// Add flutter_map and latlong2 for web
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as latlng;

String get googleApiKey => ApiConfig.googleMapsApiKey;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations?.signOut ?? 'Sign Out'),
          content: const Text('Please confirm sign out?'),
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

    if (shouldSignOut == true && mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        print('Error signing out: $e');
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

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _MapScreenWeb(signOut: _signOut) : _MapScreenMobile(signOut: _signOut);
  }
}

// --- Mobile-specific widget (using Google Maps) ---
class _MapScreenMobile extends StatefulWidget {
  final VoidCallback signOut;
  const _MapScreenMobile({required this.signOut});

  @override
  State<_MapScreenMobile> createState() => _MapScreenMobileState();
}

class _MapScreenMobileState extends State<_MapScreenMobile> {
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
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _destinationController.addListener(_onDestinationChanged);
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
        },
      );
    } catch (e) {
      print('Location error: $e');
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

  void _toggleStreetView() {
    if (_currentLatLng != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StreetViewScreen(
            startLocation: _currentLatLng!,
            endLocation: _destinationMarker?.position ?? _currentLatLng!,
            routePoints: _routePoints.isNotEmpty ? _routePoints : [_currentLatLng!],
            streetViewUrl: _generateStreetViewUrl(_currentLatLng!),
            streetViewImageUrl: _generateStreetViewImageUrl(_currentLatLng!),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location available for Street View'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _generateStreetViewImageUrl(LatLng location) {
    return 'https://maps.googleapis.com/maps/api/streetview?size=600x400&location=${location.latitude},${location.longitude}&key=$googleApiKey&heading=210&pitch=10&fov=90&source=outdoor';
  }

  String _generateStreetViewUrl(LatLng location) {
    return 'http://maps.google.com/maps?q=&layer=c&cbll=${location.latitude},${location.longitude}';
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
          infoWindow: InfoWindow(
            title: AppLocalizations.of(context)?.destination ?? 'Destination',
          ),
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
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving';

      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.couldNotOpenMaps ?? 'Could not open Google Maps'),
            ),
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
      _routePoints.clear();
    });
    if (_currentLatLng != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));
    }
    Navigator.of(context).pop();
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
        final points = _decodePolyline(polylineString);
        final steps = <Map<String, dynamic>>[];
        final legs = data['routes'][0]['legs'];
        if (legs != null && legs.isNotEmpty) {
          for (final step in legs[0]['steps']) {
            steps.add({
              'instruction': (step['html_instructions'] as String?)?.replaceAll(RegExp(r'<[^>]*>'), ''),
              'distance': step['distance']?['text'] ?? '',
              'duration': step['duration']?['text'] ?? '',
              'location': step['start_location']
            });
          }
          steps.add({
            'instruction': 'Arrive at destination',
            'distance': legs[0]['distance']?['text'] ?? '',
            'duration': legs[0]['duration']?['text'] ?? '',
            'location': legs[0]['end_location'],
          });
        }
        setState(() {
          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: points,
          );
          _routePoints = points;
          _navigationSteps = steps;
          _currentStepIndex = 0;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
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

  void _startInAppNavigation() async {
    if (_destinationMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.pleaseSetDestination ?? 'Please set a destination first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_routePolyline == null || _navigationSteps.isEmpty) {
      try {
        await _drawRoute(_currentLatLng!, _destinationMarker!.position);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)?.errorLoadingRoute ?? 'Error loading route'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
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
        _handleSelectedAIRoute(result);
      }
    }
  }

  void _openCustomPathSelection() async {
    if (_destinationMarker != null) {
      final destination = _destinationMarker!.position;
      final currentLocation = _currentLatLng ?? const LatLng(0, 0);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomPathScreen(
            origin: currentLocation,
            destination: destination,
            destinationName: _destinationController.text,
          ),
        ),
      );

      if (result != null && result is List<LatLng>) {
        _handleCustomPath(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.customPathCancelled ?? 'Custom path creation cancelled'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleCustomPath(List<LatLng> customPath) {
    setState(() {
      _routePoints = customPath;
      _navigationSteps = _convertCustomPathToSteps(customPath);
      _routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.purple,
        width: 5,
        points: customPath,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.customPathLoaded ?? 'Custom path loaded successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _convertCustomPathToSteps(List<LatLng> path) {
    List<Map<String, dynamic>> steps = [];
    if (path.isEmpty) return steps;

    steps.add({
      'instruction': 'Start from your current location',
      'distance': '0 km',
      'duration': '0 min',
      'maneuver': 'start',
      'location': {'lat': path.first.latitude, 'lng': path.first.longitude},
    });

    for (int i = 0; i < path.length - 1; i++) {
      final distance = _calculateDistance(path[i].latitude, path[i].longitude, path[i + 1].latitude, path[i + 1].longitude);
      final duration = (distance / 30 * 60).round();
      steps.add({
        'instruction': 'Continue on custom path',
        'distance': '${distance.toStringAsFixed(1)} km',
        'duration': '$duration min',
        'maneuver': 'straight',
        'location': {'lat': path[i].latitude, 'lng': path[i].longitude},
      });
    }

    steps.add({
      'instruction': 'Arrive at destination',
      'distance': '0 km',
      'duration': '0 min',
      'maneuver': 'arrive',
      'location': {'lat': path.last.latitude, 'lng': path.last.longitude},
    });

    return steps;
  }

  void _handleSelectedAIRoute(RouteOption route) {
    setState(() {
      _routePoints = route.routePoints;
      _navigationSteps = _convertRouteToSteps(route);
      _routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: _routePoints,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${route.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Map<String, dynamic>> _convertRouteToSteps(RouteOption route) {
    final steps = <Map<String, dynamic>>[];
    steps.add({
      'instruction': 'Start from your current location',
      'distance': '0 km',
      'duration': '0 min',
      'maneuver': 'start',
    });
    final points = route.routePoints;
    if (points.length > 2) {
      for (int i = 1; i < points.length - 1; i++) {
        steps.add({
          'instruction': 'Continue on ${route.name.replaceAll(RegExp(r'[🚗🌳⚡🚦🌱]'), '').trim()}',
          'distance': 'unknown',
          'duration': 'unknown',
          'maneuver': 'continue',
          'location': {
            'lat': points[i].latitude,
            'lng': points[i].longitude,
          }
        });
      }
    }
    steps.add({
      'instruction': 'Arrive at your destination',
      'distance': '${route.distance.toStringAsFixed(1)} km total',
      'duration': '${route.duration} min total',
      'maneuver': 'arrive',
    });
    return steps;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371;
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLng = (lng2 - lng1) * (math.pi / 180);
    final lat1Rad = lat1 * (math.pi / 180);
    final lat2Rad = lat2 * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _showNavigationModal() {
    if (_navigationSteps.isEmpty) {
      if (_currentLatLng != null && _destinationMarker != null) {
        _drawRoute(_currentLatLng!, _destinationMarker!.position);
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.currentLocation ?? 'Current Location',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              AppLocalizations.of(context)?.destination ?? 'Destination',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)?.steps ?? 'Steps'} ${_currentStepIndex + 1}/${_navigationSteps.length}',
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.map,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                          ),
                          Positioned(
                            left: 8,
                            top: 8,
                            child: IconButton(
                              onPressed: _currentStepIndex > 0 ? () => setModalState(() => _currentStepIndex--) : null,
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.8)),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton(
                              onPressed: _currentStepIndex < _navigationSteps.length - 1 ? () => setModalState(() => _currentStepIndex++) : null,
                              icon: const Icon(Icons.arrow_forward, color: Colors.black),
                              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${_currentStepIndex + 1} of ${_navigationSteps.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _navigationSteps[_currentStepIndex]['instruction'] ?? 'Continue forward',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _navigationSteps[_currentStepIndex]['distance'] ?? '',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  if (_navigationSteps[_currentStepIndex]['duration'] != null && _navigationSteps[_currentStepIndex]['duration'].toString().isNotEmpty)
                                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                                  if (_navigationSteps[_currentStepIndex]['duration'] != null && _navigationSteps[_currentStepIndex]['duration'].toString().isNotEmpty)
                                    Text(
                                      _navigationSteps[_currentStepIndex]['duration'],
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentStepIndex > 0 ? () => setModalState(() => _currentStepIndex--) : null,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF87CEEB), padding: const EdgeInsets.symmetric(vertical: 12)),
                                child: Text(AppLocalizations.of(context)?.previous ?? 'PREVIOUS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentStepIndex < _navigationSteps.length - 1 ? () => setModalState(() => _currentStepIndex++) : null,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4169E1), padding: const EdgeInsets.symmetric(vertical: 12)),
                                child: Text(AppLocalizations.of(context)?.next ?? 'NEXT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _openInMaps,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                                child: Text(AppLocalizations.of(context)?.openInMaps ?? 'OPEN IN MAPS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _clearNavigation,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 12)),
                                child: Text(AppLocalizations.of(context)?.clear ?? 'CLEAR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.map ?? 'Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecuritySetupScreen())),
            tooltip: 'Security Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.signOut,
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
                                  style: const TextStyle(color: Colors.black),
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
                                    title: Text(suggestion['description'], style: const TextStyle(color: Colors.black)),
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
                            onMapCreated: (controller) => _mapController = controller,
                            onTap: (location) => setState(() => _showSuggestions = false),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            markers: {
                              if (_userMarker != null) _userMarker!,
                              if (_destinationMarker != null) _destinationMarker!,
                            },
                            polylines: _routePolyline != null ? {_routePolyline!} : {},
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: FloatingActionButton(
                              heroTag: "street_view_toggle",
                              onPressed: _toggleStreetView,
                              backgroundColor: Colors.blue,
                              child: const Icon(Icons.streetview, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            child: FloatingActionButton(
                              heroTag: "sms_share",
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
                              child: const Icon(Icons.share_location, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            top: 80,
                            left: 16,
                            child: FloatingActionButton(
                              heroTag: "search_places",
                              onPressed: _openPlaceSearch,
                              backgroundColor: const Color(0xFFCAE3F2),
                              child: const Icon(Icons.search, color: Colors.black),
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
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openAIRouteSelection,
                                    icon: const Icon(Icons.psychology, color: Colors.white),
                                    label: const Text('🤖 AI Route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9C27B0),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openCustomPathSelection,
                                    icon: const Icon(Icons.edit_road, color: Colors.white),
                                    label: const Text('🛣️ Custom Path', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8E44AD),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _startInAppNavigation,
                                icon: const Icon(Icons.navigation, color: Colors.white),
                                label: Text(AppLocalizations.of(context)?.startNavigation ?? 'Start Navigation', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4169E1),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// --- Web-specific widget (using Flutter Map) ---
class _MapScreenWeb extends StatefulWidget {
  final VoidCallback signOut;
  const _MapScreenWeb({required this.signOut});

  @override
  State<_MapScreenWeb> createState() => _MapScreenWebState();
}

class _MapScreenWebState extends State<_MapScreenWeb> {
  final TextEditingController _webFromController = TextEditingController();
  final TextEditingController _webToController = TextEditingController();
  latlng.LatLng? _webFromLatLng;
  latlng.LatLng? _webToLatLng;
  final ValueNotifier<latlng.LatLng> _webMapCenter = ValueNotifier(latlng.LatLng(28.6139, 77.2090));
  final ValueNotifier<List<latlng.LatLng>> _webRoutePoints = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _webFromSuggestions = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> _webToSuggestions = ValueNotifier([]);
  final ValueNotifier<bool> _webShowFromSuggestions = ValueNotifier(false);
  final ValueNotifier<bool> _webShowToSuggestions = ValueNotifier(false);
  final ValueNotifier<List<Map<String, dynamic>>> _webGeoapifyPlaces = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _webFromController.addListener(() => _webFetchFromSuggestions(_webFromController.text));
    _webToController.addListener(() => _webFetchToSuggestions(_webToController.text));
    _webSetUserLocation();
  }

  @override
  void dispose() {
    _webFromController.removeListener(() {});
    _webToController.removeListener(() {});
    _webFromController.dispose();
    _webToController.dispose();
    _webMapCenter.dispose();
    _webRoutePoints.dispose();
    _webFromSuggestions.dispose();
    _webToSuggestions.dispose();
    super.dispose();
  }

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
      _webFromLatLng = _webMapCenter.value;
    } catch (e) {
      print('Web location error: $e');
    }
  }

  Future<void> _webFetchFromSuggestions(String query) async {
    if (query.isEmpty) {
      _webFromSuggestions.value = [];
      return;
    }
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');
    final response = await http.get(url, headers: {'User-Agent': 'safra-app/1.0'});
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      _webFromSuggestions.value = List<Map<String, dynamic>>.from(data);
    }
  }

  Future<void> _webFetchToSuggestions(String query) async {
    if (query.isEmpty) {
      _webToSuggestions.value = [];
      return;
    }
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');
    final response = await http.get(url, headers: {'User-Agent': 'safra-app/1.0'});
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      _webToSuggestions.value = List<Map<String, dynamic>>.from(data);
    }
  }

  Future<void> _webFetchRoute(latlng.LatLng start, latlng.LatLng end) async {
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
          final point = _safeLatLng(lat, lon);
          if (point != null) validPoints.add(point);
        }
        _webRoutePoints.value = validPoints;
      } else {
        _webRoutePoints.value = [];
      }
    }
  }

  latlng.LatLng? _safeLatLng(dynamic lat, dynamic lon) {
    if (lat is num && lon is num && lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180) {
      return latlng.LatLng(lat.toDouble(), lon.toDouble());
    }
    return null;
  }

  bool _isValidLatLng(latlng.LatLng? point) {
    return point != null && 
           point.latitude.isFinite && 
           point.longitude.isFinite && 
           point.latitude.abs() <= 90 && 
           point.longitude.abs() <= 180;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.map ?? 'Map'),
        actions: [
          const LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecuritySetupScreen())),
            tooltip: AppLocalizations.of(context)?.securitySettings ?? 'Security Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.signOut,
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
                          Text(AppLocalizations.of(context)?.from ?? 'From:'),
                          TextField(
                            controller: _webFromController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)?.startLocation ?? 'Start location',
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          ValueListenableBuilder<List<Map<String, dynamic>>>(
                            valueListenable: _webFromSuggestions,
                            builder: (context, suggestions, _) {
                              if (suggestions.isEmpty) return const SizedBox.shrink();
                              return Container(
                                color: Colors.white,
                                height: 120,
                                child: ListView.builder(
                                  itemCount: suggestions.length,
                                  itemBuilder: (context, index) {
                                    final s = suggestions[index];
                                    return ListTile(
                                      title: Text(s['display_name'] ?? '', style: const TextStyle(color: Colors.black)),
                                      onTap: () {
                                        final lat = double.tryParse(s['lat'] ?? '0') ?? 0;
                                        final lon = double.tryParse(s['lon'] ?? '0') ?? 0;
                                        _webFromLatLng = _safeLatLng(lat, lon);
                                        _webFromController.text = s['display_name'] ?? '';
                                        _webFromSuggestions.value = [];
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
                          Text(AppLocalizations.of(context)?.to ?? 'To:'),
                          TextField(
                            controller: _webToController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)?.destination ?? 'Destination',
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          ValueListenableBuilder<List<Map<String, dynamic>>>(
                            valueListenable: _webToSuggestions,
                            builder: (context, suggestions, _) {
                              if (suggestions.isEmpty) return const SizedBox.shrink();
                              return Container(
                                color: Colors.white,
                                height: 120,
                                child: ListView.builder(
                                  itemCount: suggestions.length,
                                  itemBuilder: (context, index) {
                                    final s = suggestions[index];
                                    return ListTile(
                                      title: Text(s['display_name'] ?? '', style: const TextStyle(color: Colors.black)),
                                      onTap: () {
                                        final lat = double.tryParse(s['lat'] ?? '0') ?? 0;
                                        final lon = double.tryParse(s['lon'] ?? '0') ?? 0;
                                        _webToLatLng = _safeLatLng(lat, lon);
                                        _webToController.text = s['display_name'] ?? '';
                                        _webToSuggestions.value = [];
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
                        if (_webFromLatLng != null && _webToLatLng != null) {
                          _webFetchRoute(_webFromLatLng!, _webToLatLng!);
                          _webMapCenter.value = _webFromLatLng!;
                        }
                      },
                      child: Text(AppLocalizations.of(context)?.getDirections ?? 'Get Directions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<latlng.LatLng>(
              valueListenable: _webMapCenter,
              builder: (context, center, _) {
                if (_safeLatLng(center.latitude, center.longitude) == null) {
                  return Center(child: Text(AppLocalizations.of(context)?.invalidMapCenter ?? 'Invalid map center. Please select valid locations.'));
                }
                return ValueListenableBuilder<List<latlng.LatLng>>(
                  valueListenable: _webRoutePoints,
                  builder: (context, routePoints, _) {
                    final validRoutePoints = routePoints.where((p) => _safeLatLng(p.latitude, p.longitude) != null).toList();
                    final markers = <fm.Marker>[];
                    if (_webFromLatLng != null) {
                      markers.add(fm.Marker(point: _webFromLatLng!, width: 40, height: 40, child: const Icon(Icons.location_pin, color: Colors.green, size: 40)));
                    }
                    if (_webToLatLng != null) {
                      markers.add(fm.Marker(point: _webToLatLng!, width: 40, height: 40, child: const Icon(Icons.location_pin, color: Colors.red, size: 40)));
                    }
                    return fm.FlutterMap(
                      options: fm.MapOptions(
                        initialCenter: center,
                        initialZoom: 13.0,
                      ),
                      children: [
                        fm.TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        fm.MarkerLayer(markers: markers),
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
          ),
        ],
      ),
    );
  }
}