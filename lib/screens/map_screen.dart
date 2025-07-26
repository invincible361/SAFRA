import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/api_config.dart';
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied.';
          _loading = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
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
      _positionStream!.listen((pos) {
        _updateUserMarker(pos);
        setState(() {
          _currentLatLng = LatLng(pos.latitude, pos.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
        if (_destinationMarker != null) {
          _drawRoute(_currentLatLng!, _destinationMarker!.position);
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _loading = false;
      });
    }
  }

  void _updateUserMarker(Position pos) {
    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
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

  void _showNavigationModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Navigation Guidance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _navigationSteps.length,
                  itemBuilder: (context, index) {
                    final step = _navigationSteps[index];
                    return ListTile(
                      leading: Text('${index + 1}'),
                      title: Text(step['instruction'] ?? ''),
                      subtitle: Text(step['distance'] ?? ''),
                      selected: index == _currentStepIndex,
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _currentStepIndex > 0
                        ? () => setState(() => _currentStepIndex--)
                        : null,
                    child: const Text('Previous'),
                  ),
                  ElevatedButton(
                    onPressed: _currentStepIndex < _navigationSteps.length - 1
                        ? () => setState(() => _currentStepIndex++)
                        : null,
                    child: const Text('Next'),
                  ),
                ],
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
        appBar: AppBar(title: const Text('Map')),
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
      appBar: AppBar(
        title: const Text('Map'),
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
                      child: GoogleMap(
                        initialCameraPosition: _initialPosition!,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: {
                          if (_userMarker != null) _userMarker!,
                          if (_destinationMarker != null) _destinationMarker!,
                        },
                        polylines: _routePolyline != null ? {_routePolyline!} : {},
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
} 