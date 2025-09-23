import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class StreetViewScreen extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> routePoints;
  final String? streetViewUrl;
  final String? streetViewImageUrl;

  const StreetViewScreen({
    Key? key,
    required this.startLocation,
    required this.endLocation,
    required this.routePoints,
    this.streetViewUrl,
    this.streetViewImageUrl,
  }) : super(key: key);

  @override
  State<StreetViewScreen> createState() => _StreetViewScreenState();
}

class _StreetViewScreenState extends State<StreetViewScreen> {
  bool _isLoading = true;
  int _currentPointIndex = 0;
  List<String> _streetViewImageUrls = [];
  List<String> _streetViewUrls = [];

  // Camera params
  double _currentHeading = 210.0;
  double _currentPitch = 10.0;
  double _currentFov = 90.0;

  @override
  void initState() {
    super.initState();
    _generateRouteStreetViews();
  }

  void _generateRouteStreetViews() {
    _streetViewImageUrls.clear();
    _streetViewUrls.clear();

    for (var point in widget.routePoints) {
      _streetViewImageUrls.add(_generateStreetViewImageUrl(point));
      _streetViewUrls.add(_generateStreetViewUrl(point));
    }

    setState(() => _isLoading = false);
  }

  void _updateStreetViewForCurrentPoint() {
    if (_currentPointIndex < widget.routePoints.length) {
      final currentPoint = widget.routePoints[_currentPointIndex];
      
      // Update the current point's street view URLs with new camera parameters
      _streetViewImageUrls[_currentPointIndex] = _generateStreetViewImageUrl(currentPoint);
      _streetViewUrls[_currentPointIndex] = _generateStreetViewUrl(currentPoint);
      
      setState(() {
        // Trigger rebuild to show updated street view
      });
    }
  }

  String _generateStreetViewImageUrl(LatLng location) {
    final apiKey = ApiConfig.googleMapsApiKey;
    return 'https://maps.googleapis.com/maps/api/streetview?size=800x600&location=${location.latitude},${location.longitude}&key=$apiKey&heading=${_currentHeading.toInt()}&pitch=${_currentPitch.toInt()}&fov=${_currentFov.toInt()}&source=outdoor';
  }

  String _generateStreetViewUrl(LatLng location) {
    return 'https://www.google.com/maps/@${location.latitude},${location.longitude},3a,75y,${_currentHeading.toInt()}h,${_currentPitch.toInt()}t/data=!3m6!1e1';
  }

  Future<void> _openInMaps() async {
    if (_currentPointIndex < _streetViewUrls.length) {
      final Uri url = Uri.parse(_streetViewUrls[_currentPointIndex]);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open Street View in Maps');
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPoint = widget.routePoints[_currentPointIndex];
    final currentImageUrl = _streetViewImageUrls.isNotEmpty
        ? _streetViewImageUrls[_currentPointIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF111416),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D21),
        elevation: 0,
        title: const Text(
          "360° Street View",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Color(0xFFCAE3F2)),
            onPressed: _openInMaps,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D21),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Location",
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    Text(
                      "Lat: ${currentPoint.latitude.toStringAsFixed(5)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "Lng: ${currentPoint.longitude.toStringAsFixed(5)}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // Right
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Heading: ${_currentHeading.toInt()}°",
                        style:
                        const TextStyle(color: Color(0xFFCAE3F2))),
                    Text("Pitch: ${_currentPitch.toInt()}°",
                        style: const TextStyle(color: Colors.grey)),
                    Text("FOV: ${_currentFov.toInt()}°",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          // Street View Image
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(16),
              ),
              child: currentImageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    // Rotate based on horizontal drag
                    setState(() {
                      _currentHeading += details.delta.dx * 2; // Sensitivity multiplier
                      // Keep heading between 0-360 degrees
                      if (_currentHeading > 360) _currentHeading -= 360;
                      if (_currentHeading < 0) _currentHeading += 360;
                    });
                    // Regenerate street view with new heading
                    _updateStreetViewForCurrentPoint();
                  },
                  onVerticalDragUpdate: (details) {
                    // Adjust pitch based on vertical drag
                    setState(() {
                      _currentPitch += details.delta.dy * 0.5; // Sensitivity multiplier
                      // Keep pitch between -90 and 90 degrees
                      _currentPitch = _currentPitch.clamp(-90.0, 90.0);
                    });
                    // Regenerate street view with new pitch
                    _updateStreetViewForCurrentPoint();
                  },
                  onScaleUpdate: (details) {
                    // Adjust FOV based on pinch/scale
                    setState(() {
                      _currentFov += (details.scale - 1) * 10; // Sensitivity multiplier
                      // Keep FOV between 30 and 120 degrees
                      _currentFov = _currentFov.clamp(30.0, 120.0);
                    });
                    // Regenerate street view with new FOV
                    _updateStreetViewForCurrentPoint();
                  },
                  child: Stack(
                    children: [
                      Image.network(
                        currentImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFCAE3F2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.error,
                              color: Colors.red, size: 48),
                        ),
                      ),
                      // Interaction hint overlay
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Swipe to rotate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : const Center(
                child: Icon(Icons.streetview,
                    color: Colors.grey, size: 64),
              ),
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Reset camera button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentHeading = 210.0;
                        _currentPitch = 10.0;
                        _currentFov = 90.0;
                      });
                      _updateStreetViewForCurrentPoint();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Reset View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Previous/Next buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavButton(Icons.arrow_back, "Previous",
                        enabled: _currentPointIndex > 0, onTap: () {
                          setState(() => _currentPointIndex--);
                          // Reset camera parameters when changing points
                          _currentHeading = 210.0;
                          _currentPitch = 10.0;
                          _currentFov = 90.0;
                        }),
                    _buildNavButton(Icons.arrow_forward, "Next",
                        enabled: _currentPointIndex < widget.routePoints.length - 1,
                        onTap: () {
                          setState(() => _currentPointIndex++);
                          // Reset camera parameters when changing points
                          _currentHeading = 210.0;
                          _currentPitch = 10.0;
                          _currentFov = 90.0;
                        }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label,
      {required bool enabled, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
        enabled ? const Color(0xFFCAE3F2) : Colors.grey[700],
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
