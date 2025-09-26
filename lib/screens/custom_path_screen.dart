import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../config/api_config.dart';
import '../widgets/translated_text.dart';

class CustomPathScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String destinationName;

  const CustomPathScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<CustomPathScreen> createState() => _CustomPathScreenState();
}

class _CustomPathScreenState extends State<CustomPathScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _customPath = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  List<LatLng> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    _markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.origin,
        infoWindow: const InfoWindow(title: 'Start'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(title: widget.destinationName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    // Add default route
    _generateDefaultRoute();
  }

  Future<void> _generateDefaultRoute() async {
    setState(() => _isLoading = true);
    
    try {
      // Create a simple straight line route for now
      final points = [
        widget.origin,
        widget.destination,
      ];
      
      setState(() {
        _customPath = points;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('default_route'),
            points: points,
            color: Colors.blue,
            width: 4,
          ),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate route: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=${ApiConfig.googleMapsApiKey}',
        ),
      );

      final data = json.decode(response.body);
      // Parse response and extract coordinates
      // This is a simplified implementation
      setState(() {
        _showSearchResults = true;
        // Add mock results for demonstration
        _searchResults = [
          const LatLng(12.9716, 77.5946), // Bangalore
          const LatLng(28.6139, 77.2090), // Delhi
        ];
      });
    } catch (e) {
      print('Search error: $e');
    }
  }

  void _addWaypoint(LatLng waypoint) {
    setState(() {
      final waypointId = 'waypoint_${_markers.length}';
      _markers.add(
        Marker(
          markerId: MarkerId(waypointId),
          position: waypoint,
          infoWindow: InfoWindow(title: 'Waypoint ${_markers.length}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          draggable: true,
          onDragEnd: (newPosition) => _updateWaypointById(waypointId, newPosition),
        ),
      );
      _regenerateRoute();
    });
  }

  void _updateWaypointById(String markerId, LatLng newPosition) {
    setState(() {
      _markers = _markers.map((marker) {
        if (marker.markerId.value == markerId) {
          return marker.copyWith(positionParam: newPosition);
        }
        return marker;
      }).toSet();
      _regenerateRoute();
    });
  }

  void _updateWaypoint(LatLng oldPosition, LatLng newPosition) {
    setState(() {
      _markers = _markers.map((marker) {
        if (marker.position == oldPosition) {
          return marker.copyWith(positionParam: newPosition);
        }
        return marker;
      }).toSet();
      _regenerateRoute();
    });
  }

  Future<void> _regenerateRoute() async {
    if (_markers.length < 2) return;

    setState(() => _isLoading = true);

    try {
      // Get all waypoints including origin and destination
      final allPoints = _markers
          .map((marker) => marker.position)
          .toList();

      // Sort waypoints by distance from origin to create a logical route
      allPoints.sort((a, b) {
        final distanceA = _calculateDistance(widget.origin, a);
        final distanceB = _calculateDistance(widget.origin, b);
        return distanceA.compareTo(distanceB);
      });
      
      setState(() {
        _customPath = allPoints;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('custom_route'),
            points: allPoints,
            color: Colors.purple,
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to regenerate route: $e';
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = point1.latitude * (3.14159265359 / 180);
    final double lat2Rad = point2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final double a = (deltaLatRad / 2) * (deltaLatRad / 2) +
        (1 - (deltaLatRad / 2) * (deltaLatRad / 2) - (lat1Rad - lat2Rad) / 2 * (lat1Rad - lat2Rad) / 2) *
        (deltaLngRad / 2) * (deltaLngRad / 2);
    final double c = 2 * (1 / (1 - a).abs()).abs();

    return earthRadius * c;
  }

  void _removeWaypoint(MarkerId markerId) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == markerId);
      _regenerateRoute();
    });
  }

  void _onMapTap(LatLng position) {
    // Add waypoint on tap
    _addWaypoint(position);
  }

  void _saveCustomPath() {
    // Show confirmation dialog asking if user wants to use this path
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.useCustomPath ?? 'Use Custom Path?'),
          content: Text(AppLocalizations.of(context)?.useCustomPathDescription ?? 'Do you want to use this custom path for navigation?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context, null); // Return null to indicate no path selected
              },
              child: Text(AppLocalizations.of(context)?.no ?? 'No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(context, _customPath); // Return the custom path
              },
              child: Text(AppLocalizations.of(context)?.yes ?? 'Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TranslatedText(
          text: 'Custom Path Selection',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111416),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _markers = {
                  _markers.firstWhere((m) => m.markerId.value == 'origin'),
                  _markers.firstWhere((m) => m.markerId.value == 'destination'),
                };
                _polylines.clear();
                _customPath.clear();
              });
            },
            tooltip: 'Clear Waypoints',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: widget.origin,
              zoom: 12.0,
            ),
            markers: _markers,
            polylines: _polylines,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: true,
          ),
          
          // Search Bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                            hintText: 'Search for places...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchLocation('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _searchLocation,
                    ),
                    if (_showSearchResults && _searchResults.isNotEmpty)
                      GestureDetector(
                        onTap: () {}, // Absorb tap events
                        child: SizedBox(
                          height: 100,
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                title: Text('Location ${index + 1}'),
                                subtitle: Text('${result.latitude}, ${result.longitude}'),
                                onTap: () {
                                  _addWaypoint(result);
                                  _searchController.clear();
                                  _showSearchResults = false;
                                },
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Error Message
          if (_error != null)
            Positioned(
              top: 200,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.blue),
                    const SizedBox(height: 8),
                    TranslatedText(
                      text: 'Tap on the map to add waypoints',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    TranslatedText(
                      text: 'Drag waypoints to adjust your route',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _customPath.isNotEmpty ? _saveCustomPath : null,
        icon: const Icon(Icons.save),
        label: TranslatedText(
          text: 'Save Custom Path',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _customPath.isNotEmpty ? Colors.green : Colors.grey,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
