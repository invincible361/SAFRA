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
  bool _hasError = false;
  String? _errorMessage;
  int _currentPointIndex = 0;
  List<String> _streetViewImageUrls = [];
  List<String> _streetViewUrls = [];
  
  // 360-degree navigation variables
  double _currentHeading = 210.0; // Default heading
  double _currentPitch = 10.0; // Default pitch
  double _currentFov = 90.0; // Field of view
  bool _isMoving = false;

  // Gesture control variables
  double _lastScale = 1.0;
  double _lastHeading = 210.0;
  double _lastPitch = 10.0;
  double _lastFov = 90.0;

  @override
  void initState() {
    super.initState();
    _generateRouteStreetViews();
  }

  void _generateRouteStreetViews() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _streetViewImageUrls.clear();
      _streetViewUrls.clear();
    });

    // Generate Street View URLs for all route points
    for (int i = 0; i < widget.routePoints.length; i++) {
      final point = widget.routePoints[i];
      final imageUrl = _generateStreetViewImageUrl(point);
      final streetViewUrl = _generateStreetViewUrl(point);
      
      _streetViewImageUrls.add(imageUrl);
      _streetViewUrls.add(streetViewUrl);
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _generateStreetViewImageUrl(LatLng location) {
    return 'https://maps.googleapis.com/maps/api/streetview?size=600x400&location=${location.latitude},${location.longitude}&key=AIzaSyA1nhqmZMTFmqktFcJML_6WR5PDFGqH6N8&heading=${_currentHeading.toInt()}&pitch=${_currentPitch.toInt()}&fov=${_currentFov.toInt()}&source=outdoor';
  }

  String _generateStreetViewUrl(LatLng location) {
    return 'https://www.google.com/maps/@${location.latitude},${location.longitude},3a,75y,${_currentHeading.toInt()}h,${_currentPitch.toInt()}t/data=!3m6!1e1!3m4!1s!2e0!7i16384!8i8192';
  }

  void _nextPoint() {
    if (_currentPointIndex < widget.routePoints.length - 1) {
      setState(() {
        _currentPointIndex++;
        _isMoving = true;
      });
      _updateStreetViewImage();
    }
  }

  void _previousPoint() {
    if (_currentPointIndex > 0) {
      setState(() {
        _currentPointIndex--;
        _isMoving = true;
      });
      _updateStreetViewImage();
    }
  }

  void _updateStreetViewImage() {
    // Update the current image URL with new parameters
    if (_currentPointIndex < _streetViewImageUrls.length) {
      final currentPoint = widget.routePoints[_currentPointIndex];
      final newImageUrl = _generateStreetViewImageUrl(currentPoint);
      setState(() {
        _streetViewImageUrls[_currentPointIndex] = newImageUrl;
        _isMoving = false;
      });
    }
  }

  // 360-degree navigation methods
  void _rotateLeft() {
    setState(() {
      _currentHeading = (_currentHeading - 45) % 360;
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _rotateRight() {
    setState(() {
      _currentHeading = (_currentHeading + 45) % 360;
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _lookUp() {
    setState(() {
      _currentPitch = (_currentPitch + 10).clamp(-90.0, 90.0);
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _lookDown() {
    setState(() {
      _currentPitch = (_currentPitch - 10).clamp(-90.0, 90.0);
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _zoomIn() {
    setState(() {
      _currentFov = (_currentFov - 10).clamp(30.0, 120.0);
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _zoomOut() {
    setState(() {
      _currentFov = (_currentFov + 10).clamp(30.0, 120.0);
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  // Gesture control methods
  void _handleHorizontalDrag(DragUpdateDetails details) {
    // Horizontal drag controls rotation (heading)
    double sensitivity = 0.5; // Adjust sensitivity as needed
    double delta = details.delta.dx * sensitivity;
    
    setState(() {
      _currentHeading = (_currentHeading - delta) % 360;
      if (_currentHeading < 0) _currentHeading += 360;
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    // Vertical drag controls pitch (looking up/down)
    double sensitivity = 0.5; // Adjust sensitivity as needed
    double delta = details.delta.dy * sensitivity;
    
    setState(() {
      _currentPitch = (_currentPitch + delta).clamp(-90.0, 90.0);
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastScale = 1.0;
    _lastHeading = _currentHeading;
    _lastPitch = _currentPitch;
    _lastFov = _currentFov;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle zoom with scale gesture
    double scaleFactor = details.scale / _lastScale;
    double newFov = (_lastFov / scaleFactor).clamp(30.0, 120.0);
    
    setState(() {
      _currentFov = newFov;
      _isMoving = true;
    });
    _updateStreetViewImage();
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastScale = 1.0;
  }

  Future<void> _openInMaps() async {
    if (_currentPointIndex < _streetViewUrls.length) {
      try {
        final Uri url = Uri.parse(_streetViewUrls[_currentPointIndex]);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar('Could not open Street View in Maps');
        }
      } catch (e) {
        _showErrorSnackBar('Error opening Street View: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routePoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Street View'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No route points available'),
        ),
      );
    }

    final currentPoint = widget.routePoints[_currentPointIndex];
    final currentImageUrl = _currentPointIndex < _streetViewImageUrls.length 
        ? _streetViewImageUrls[_currentPointIndex] 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('360° Street View'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInMaps,
            tooltip: 'Open in Maps',
          ),
        ],
      ),
      body: Column(
        children: [
          // Route progress and location info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Route Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${_currentPointIndex + 1} / ${widget.routePoints.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentPointIndex + 1) / widget.routePoints.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${currentPoint.latitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Lng: ${currentPoint.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'View Controls',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heading: ${_currentHeading.toInt()}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Pitch: ${_currentPitch.toInt()}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'FOV: ${_currentFov.toInt()}°',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Street View Image with 360 controls
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: currentImageUrl != null
                        ? RawGestureDetector(
                            gestures: {
                              HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                                () => HorizontalDragGestureRecognizer(),
                                (HorizontalDragGestureRecognizer instance) {
                                  instance.onUpdate = _handleHorizontalDrag;
                                },
                              ),
                              VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                                (VerticalDragGestureRecognizer instance) {
                                  instance.onUpdate = _handleVerticalDrag;
                                },
                              ),
                              ScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
                                () => ScaleGestureRecognizer(),
                                (ScaleGestureRecognizer instance) {
                                  instance.onStart = _handleScaleStart;
                                  instance.onUpdate = _handleScaleUpdate;
                                  instance.onEnd = _handleScaleEnd;
                                },
                              ),
                            },
                            child: Image.network(
                              currentImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
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
                                        const SizedBox(height: 16),
                                        Text(
                                          _isMoving ? 'Updating view...' : 'Loading Street View...',
                                          style: TextStyle(
                                            fontSize: 16,
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
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.red[600],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Failed to load Street View',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No Street View available at this location',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _openInMaps,
                                          icon: const Icon(Icons.open_in_new),
                                          label: const Text('Open in Maps'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.streetview,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Street View Image',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Street View image URL not available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                // 360-degree navigation controls
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      // Gesture hint
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '👆 Drag to rotate',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '📱 Pinch to zoom',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Zoom controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: _zoomIn,
                              icon: const Icon(Icons.zoom_in),
                              tooltip: 'Zoom In (or pinch)',
                            ),
                            IconButton(
                              onPressed: _zoomOut,
                              icon: const Icon(Icons.zoom_out),
                              tooltip: 'Zoom Out (or pinch)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Look controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              onPressed: _lookUp,
                              icon: const Icon(Icons.keyboard_arrow_up),
                              tooltip: 'Look Up (or drag up)',
                            ),
                            IconButton(
                              onPressed: _lookDown,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              tooltip: 'Look Down (or drag down)',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Rotation controls
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _rotateLeft,
                          icon: const Icon(Icons.rotate_left),
                          tooltip: 'Rotate Left (or drag left)',
                        ),
                        IconButton(
                          onPressed: _rotateRight,
                          icon: const Icon(Icons.rotate_right),
                          tooltip: 'Rotate Right (or drag right)',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Navigation and action buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Route navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentPointIndex > 0 ? _previousPoint : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _currentPointIndex < widget.routePoints.length - 1 ? _nextPoint : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openInMaps,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
  }
} 