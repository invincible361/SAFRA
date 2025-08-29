import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  String _generateStreetViewImageUrl(LatLng location) {
    return 'https://maps.googleapis.com/maps/api/streetview?size=800x600&location=${location.latitude},${location.longitude}&key=YOUR_GOOGLE_API_KEY&heading=${_currentHeading.toInt()}&pitch=${_currentPitch.toInt()}&fov=${_currentFov.toInt()}&source=outdoor';
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
                child: Image.network(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(Icons.arrow_back, "Previous",
                    enabled: _currentPointIndex > 0, onTap: () {
                      setState(() => _currentPointIndex--);
                    }),
                _buildNavButton(Icons.arrow_forward, "Next",
                    enabled: _currentPointIndex < widget.routePoints.length - 1,
                    onTap: () {
                      setState(() => _currentPointIndex++);
                    }),
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
